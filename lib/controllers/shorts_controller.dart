import 'dart:convert';

import 'package:get/get.dart';
import '../core/exceptions/github_exception.dart';
import '../data/repositories/github_repository.dart';
import '../services/github_service.dart';

/// Manages the Shorts (vertical drama) data in dramahub-data:
///   shorts/config.json        — on/off + ad rules
///   shorts/feed.json          — series shown in the app's Shorts tab
///   shorts/series/<id>.json   — all episodes of one series
///
/// Every save bumps `data_version` in config.json so the app refreshes
/// its cache right away. Commit messages are prefixed "Shorts:".
class ShortsController extends GetxController {
  final GitHubService _service = Get.find<GitHubService>();
  late final GitHubRepository _repository = GitHubRepository(_service);

  static const String configPath = 'shorts/config.json';
  static const String feedPath = 'shorts/feed.json';
  static const String seriesDir = 'shorts/series';

  static const Map<String, dynamic> defaultConfig = {
    'enabled': false,
    'data_version': 1,
    'min_build': 0,
    'use_signed_urls': false,
    'free_episodes_default': 10,
    'max_players': 3,
    'ads': {
      'interstitial_enabled': true,
      'interstitial_every_n_episodes': 4,
      'interstitial_first_after': 3,
      'interstitial_screen_key': 'shorts_feed',
      'rewarded_unlock_enabled': true,
      'unlock_episodes_per_ad': 3,
      'unlock_on_no_fill': false,
      'rewarded_screen_key': 'shorts_unlock',
    },
  };

  final RxMap<String, dynamic> config = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> feed = <Map<String, dynamic>>[].obs;

  /// All series files (including ones not shown in the feed), by id.
  final RxMap<String, Map<String, dynamic>> series =
      <String, Map<String, dynamic>>{}.obs;

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  static final RegExp idPattern = RegExp(r'^[a-z0-9_]+$');

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  // ── Loading ──────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = '';
    _repository.clearCache();
    try {
      final c = await _fetchOrNull(configPath);
      config.assignAll(
        c is Map<String, dynamic>
            ? _mergeDefaults(c)
            : Map<String, dynamic>.from(defaultConfig),
      );

      final f = await _fetchOrNull(feedPath);
      feed.assignAll(
        f is List
            ? f.whereType<Map>().map((e) => Map<String, dynamic>.from(e))
            : <Map<String, dynamic>>[],
      );

      final names = await _service.listDirectory(seriesDir);
      final loaded = <String, Map<String, dynamic>>{};
      for (final name in names) {
        if (!name.endsWith('.json') || name.startsWith('_')) continue;
        final data = await _fetchOrNull('$seriesDir/$name');
        if (data is Map<String, dynamic> && data['id'] is String) {
          loaded[data['id'] as String] = data;
        }
      }
      series.assignAll(loaded);
      await _resyncFeed();
    } catch (e) {
      errorMessage.value = 'Failed to load Shorts data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<dynamic> _fetchOrNull(String path) async {
    try {
      return await _repository.fetchJsonList(path);
    } on GitHubApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Map<String, dynamic> _mergeDefaults(Map<String, dynamic> c) {
    final merged = Map<String, dynamic>.from(defaultConfig)..addAll(c);
    final ads = Map<String, dynamic>.from(defaultConfig['ads'] as Map);
    if (c['ads'] is Map) ads.addAll(Map<String, dynamic>.from(c['ads']));
    merged['ads'] = ads;
    return merged;
  }

  // ── Getters for the UI ───────────────────────────────────────────────────

  bool get enabled => config['enabled'] == true;
  int get dataVersion => (config['data_version'] as num?)?.toInt() ?? 0;
  Map<String, dynamic> get ads =>
      Map<String, dynamic>.from(config['ads'] as Map? ?? {});

  bool isInFeed(String id) => feed.any((e) => e['id'] == id);

  List<Map<String, dynamic>> episodesOf(String id) =>
      ((series[id]?['episodes'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  // ── Settings ─────────────────────────────────────────────────────────────

  /// Saves top-level config fields and ad fields together.
  Future<bool> saveSettings({
    Map<String, dynamic> fields = const {},
    Map<String, dynamic> adFields = const {},
  }) async {
    return _guard(() async {
      final next = Map<String, dynamic>.from(config)..addAll(fields);
      next['ads'] = ads..addAll(adFields);
      config.assignAll(next);
      await _commitConfig('Shorts: update settings');
    });
  }

  // ── Series ───────────────────────────────────────────────────────────────

  /// Builds episode maps from a URL pattern containing `{n}`.
  static List<Map<String, dynamic>> generateEpisodes({
    required int from,
    required int to,
    required String type, // 'hls' | 'mp4'
    required String pattern,
    String thumbPattern = '',
  }) {
    return [
      for (var n = from; n <= to; n++)
        {
          'n': n,
          'title': 'Episode $n',
          type: pattern.replaceAll('{n}', '$n'),
          if (thumbPattern.isNotEmpty)
            'thumb': thumbPattern.replaceAll('{n}', '$n'),
        },
    ];
  }

  /// Returns a list of problems; empty = valid.
  List<String> validateSeries(Map<String, dynamic> s, {required bool isNew}) {
    final errors = <String>[];
    final id = s['id'] as String? ?? '';
    if (!idPattern.hasMatch(id)) {
      errors.add('ID must be lowercase letters, numbers and _ only.');
    }
    if (isNew && series.containsKey(id)) {
      errors.add('A series with ID "$id" already exists.');
    }
    if ((s['title'] as String? ?? '').trim().isEmpty) {
      errors.add('Title is required.');
    }
    final poster = s['poster'] as String? ?? '';
    if (poster.isNotEmpty && !poster.startsWith('https://')) {
      errors.add('Poster URL must start with https://');
    }
    final eps = (s['episodes'] as List?) ?? const [];
    if (eps.isEmpty) errors.add('At least one episode is required.');
    final seen = <int>{};
    for (final e in eps.whereType<Map>()) {
      final n = e['n'];
      if (n is! int || n <= 0) {
        errors.add('Every episode needs a positive number.');
        break;
      }
      if (!seen.add(n)) errors.add('Episode $n is listed twice.');
      final url = (e['hls'] ?? e['mp4'] ?? '') as String;
      if (!url.startsWith('https://')) {
        errors.add('Episode $n: video URL must start with https://');
      }
    }
    return errors;
  }

  /// Creates or updates a series file, keeps the feed entry in sync.
  Future<bool> saveSeries(
    Map<String, dynamic> s, {
    required bool isNew,
    bool addToFeed = false,
  }) async {
    final errors = validateSeries(s, isNew: isNew);
    if (errors.isNotEmpty) {
      errorMessage.value = errors.join('\n');
      return false;
    }
    return _guard(() async {
      final data = _normalized(s);
      final id = data['id'] as String;
      await _repository.commitJsonList(
        path: '$seriesDir/$id.json',
        data: data,
        message: 'Shorts: ${isNew ? 'add' : 'update'} series $id',
      );
      series[id] = data;

      final inFeed = isInFeed(id);
      if (inFeed || addToFeed) {
        final entry = feedEntryFor(data);
        final i = feed.indexWhere((e) => e['id'] == id);
        if (i >= 0) {
          feed[i] = entry;
        } else {
          feed.add(entry);
        }
        await _commitFeed('Shorts: sync feed for $id');
      }
      await _commitConfig('Shorts: bump data_version');
    });
  }

  /// Adds generated episodes from `last+1` up to [upTo] using the pattern
  /// stored with the series. Existing episodes are never changed.
  Future<bool> extendEpisodes(String id, int upTo) async {
    final s = series[id];
    final admin = s?['_admin'];
    if (s == null || admin is! Map || (admin['pattern'] ?? '') == '') {
      errorMessage.value =
          'This series has no saved URL pattern. Edit it and set one first.';
      return false;
    }
    final eps = episodesOf(id);
    final last = eps.fold<int>(0, (m, e) => (e['n'] as int) > m ? e['n'] as int : m);
    if (upTo <= last) {
      errorMessage.value = 'Series already has $last episodes.';
      return false;
    }
    final next = Map<String, dynamic>.from(s);
    next['episodes'] = [
      ...eps,
      ...generateEpisodes(
        from: last + 1,
        to: upTo,
        type: admin['type'] as String? ?? 'hls',
        pattern: admin['pattern'] as String,
        thumbPattern: admin['thumbPattern'] as String? ?? '',
      ),
    ];
    return saveSeries(next, isNew: false);
  }

  Future<bool> saveEpisode(String id, Map<String, dynamic> ep) async {
    final s = series[id];
    if (s == null) return false;
    final eps = episodesOf(id)..removeWhere((e) => e['n'] == ep['n']);
    eps.add(ep);
    return saveSeries({...s, 'episodes': eps}, isNew: false);
  }

  Future<bool> deleteEpisode(String id, int n) async {
    final s = series[id];
    if (s == null) return false;
    final eps = episodesOf(id)..removeWhere((e) => e['n'] == n);
    return saveSeries({...s, 'episodes': eps}, isNew: false);
  }

  Future<bool> deleteSeries(String id) async {
    return _guard(() async {
      if (isInFeed(id)) {
        feed.removeWhere((e) => e['id'] == id);
        await _commitFeed('Shorts: remove $id from feed');
      }
      final path = '$seriesDir/$id.json';
      try {
        final file = await _service.fetchFile(path);
        await _service.deleteFile(
          path: path,
          sha: file.sha,
          message: 'Shorts: delete series $id',
        );
      } on GitHubApiException catch (e) {
        if (e.statusCode != 404) rethrow;
      }
      series.remove(id);
      await _commitConfig('Shorts: bump data_version');
    });
  }

  // ── Feed ─────────────────────────────────────────────────────────────────

  Future<bool> setInFeed(String id, bool show) async {
    final s = series[id];
    if (s == null || isInFeed(id) == show) return true;
    return _guard(() async {
      if (show) {
        feed.add(feedEntryFor(s));
      } else {
        feed.removeWhere((e) => e['id'] == id);
      }
      await _commitFeed('Shorts: ${show ? 'show' : 'hide'} $id in feed');
      await _commitConfig('Shorts: bump data_version');
    });
  }

  Future<bool> moveInFeed(String id, int delta) async {
    final i = feed.indexWhere((e) => e['id'] == id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= feed.length) return true;
    return _guard(() async {
      final item = feed.removeAt(i);
      feed.insert(j, item);
      await _commitFeed('Shorts: reorder feed');
      await _commitConfig('Shorts: bump data_version');
    });
  }

  /// The feed entry is always rebuilt from the series file (episode 1 =
  /// the hook), so title/poster/episode count never drift.
  static Map<String, dynamic> feedEntryFor(Map<String, dynamic> s) {
    final eps = ((s['episodes'] as List?) ?? const [])
        .whereType<Map>()
        .toList()
      ..sort((a, b) => (a['n'] as int).compareTo(b['n'] as int));
    final first = eps.isEmpty ? <String, dynamic>{} : eps.first;
    return {
      'id': s['id'],
      'title': s['title'] ?? '',
      'description': s['description'] ?? '',
      'poster': s['poster'] ?? '',
      if ((s['genre'] ?? '').toString().isNotEmpty) 'genre': s['genre'],
      if (s['tags'] is List && (s['tags'] as List).isNotEmpty)
        'tags': s['tags'],
      'totalEpisodes': s['totalEpisodes'] ?? eps.length,
      'episode': {
        for (final k in ['n', 'title', 'hls', 'mp4', 'thumb'])
          if (first[k] != null) k: first[k],
      },
    };
  }

  // ── Internals ────────────────────────────────────────────────────────────

  Map<String, dynamic> _normalized(Map<String, dynamic> s) {
    final eps = ((s['episodes'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) => (a['n'] as int).compareTo(b['n'] as int));
    return {
      ...s,
      'totalEpisodes': eps.length,
      'episodes': eps,
    };
  }

  /// Rebuilds feed entries from their series files (keeps order) and saves
  /// only if something changed — e.g. older entries missing genre/tags.
  Future<void> _resyncFeed() async {
    var changed = false;
    for (var i = 0; i < feed.length; i++) {
      final s = series[feed[i]['id']];
      if (s == null) continue;
      final entry = feedEntryFor(s);
      if (jsonEncode(entry) != jsonEncode(feed[i])) {
        feed[i] = entry;
        changed = true;
      }
    }
    if (changed) await _commitFeed('Shorts: resync feed entries');
  }

  Future<void> _commitFeed(String message) => _repository.commitJsonList(
        path: feedPath,
        data: feed.toList(),
        message: message,
      );

  Future<void> _commitConfig(String message) {
    config['data_version'] = dataVersion + 1;
    return _repository.commitJsonList(
      path: configPath,
      data: Map<String, dynamic>.from(config),
      message: message,
    );
  }

  Future<bool> _guard(Future<void> Function() action) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await action();
      return true;
    } catch (e) {
      // Reload so the screen shows what is really on GitHub.
      await loadAll();
      errorMessage.value = 'Save failed: $e';
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
