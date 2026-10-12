import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/shorts_controller.dart';
import '../widgets/dialogs/confirm_dialog.dart';

const String _cdnBase = 'https://cdn.dramahubs.stream/shorts';

class ShortsManagerPage extends StatelessWidget {
  const ShortsManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ShortsController>();
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Shorts', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Obx(() => _Pill(
                      text: c.enabled ? 'LIVE' : 'OFF',
                      color: c.enabled ? Colors.green : Colors.grey,
                    )),
                const SizedBox(width: 8),
                Obx(() => Text('data_version ${c.dataVersion}',
                    style: const TextStyle(color: Colors.black45))),
                const Spacer(),
                Obx(() => c.isSaving.value
                    ? const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const SizedBox.shrink()),
                IconButton(
                  tooltip: 'Reload from GitHub',
                  icon: const Icon(Icons.refresh),
                  onPressed: c.loadAll,
                ),
              ],
            ),
            Obx(() => c.errorMessage.value.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(c.errorMessage.value,
                        style: TextStyle(color: Colors.red.shade800)),
                  )),
            const TabBar(
              labelColor: Colors.deepPurple,
              indicatorColor: Colors.deepPurple,
              tabs: [Tab(text: 'Series'), Tab(text: 'Settings')],
            ),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const TabBarView(
                  children: [_SeriesTab(), _SettingsTab()],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══ Series tab ══════════════════════════════════════════════════════════════

class _SeriesTab extends StatelessWidget {
  const _SeriesTab();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ShortsController>();
    return Obx(() {
      // Feed order first, then series not shown in the feed.
      final feedIds = c.feed.map((e) => e['id'] as String?).toList();
      final ordered = [
        ...feedIds.whereType<String>().where(c.series.containsKey),
        ...c.series.keys.where((id) => !feedIds.contains(id)).toList()..sort(),
      ];
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _SeriesFormDialog.show(context),
                icon: const Icon(Icons.add),
                label: const Text('Add series'),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Upload videos to R2 first (rclone), then add the series here. '
                  'Order in the app = order of "Shown in app" series below.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ordered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No series yet.')),
            ),
          for (final id in ordered) _SeriesCard(id: id),
        ],
      );
    });
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ShortsController>();
    final s = c.series[id]!;
    final eps = c.episodesOf(id);
    final inFeed = c.isInFeed(id);
    final feedIndex = c.feed.indexWhere((e) => e['id'] == id);
    final poster = s['poster'] as String? ?? '';
    final free = s['freeEpisodes'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 54,
                height: 96,
                child: poster.isEmpty
                    ? Container(color: Colors.black12)
                    : Image.network(poster,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: Colors.black12,
                              child: const Icon(Icons.image_not_supported,
                                  size: 18),
                            )),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['title'] as String? ?? id,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(id, style: const TextStyle(color: Colors.black45)),
                  const SizedBox(height: 6),
                  Text(
                    '${eps.length} episodes · '
                    '${free == null ? 'free: default' : 'free: $free'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Shown in app', style: TextStyle(fontSize: 12)),
                    Switch(
                      value: inFeed,
                      onChanged: (v) => c.setInFeed(id, v),
                    ),
                  ],
                ),
                if (inFeed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Move up',
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        onPressed:
                            feedIndex > 0 ? () => c.moveInFeed(id, -1) : null,
                      ),
                      Text('#${feedIndex + 1}'),
                      IconButton(
                        tooltip: 'Move down',
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        onPressed: feedIndex < c.feed.length - 1
                            ? () => c.moveInFeed(id, 1)
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'extend':
                    _ExtendDialog.show(context, id, eps.length);
                  case 'episodes':
                    _EpisodesDialog.show(context, id);
                  case 'edit':
                    _SeriesFormDialog.show(context, existing: s);
                  case 'test':
                    if (eps.isNotEmpty) {
                      final url = (eps.first['hls'] ?? eps.first['mp4']) as String;
                      launchUrl(Uri.parse(url));
                    }
                  case 'delete':
                    final ok = await showConfirmDialog(
                      context,
                      'Delete "${s['title']}"?',
                      'Removes it from the app and deletes $id.json from GitHub. '
                          'Videos on R2 are NOT deleted.',
                    );
                    if (ok) c.deleteSeries(id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'extend', child: Text('Add new episodes')),
                PopupMenuItem(value: 'episodes', child: Text('Edit episodes')),
                PopupMenuItem(value: 'edit', child: Text('Edit series info')),
                PopupMenuItem(value: 'test', child: Text('Open episode 1 link')),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete series',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / edit series ───────────────────────────────────────────────────────

class _SeriesFormDialog extends StatefulWidget {
  const _SeriesFormDialog({this.existing});
  final Map<String, dynamic>? existing;

  static Future<void> show(BuildContext context,
      {Map<String, dynamic>? existing}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SeriesFormDialog(existing: existing),
    );
  }

  @override
  State<_SeriesFormDialog> createState() => _SeriesFormDialogState();
}

class _SeriesFormDialogState extends State<_SeriesFormDialog> {
  final c = Get.find<ShortsController>();
  late final bool isNew = widget.existing == null;
  late final Map<String, dynamic> admin =
      Map<String, dynamic>.from(widget.existing?['_admin'] as Map? ?? {});

  late final title = TextEditingController(text: _s('title'));
  late final id = TextEditingController(text: _s('id'));
  late final description = TextEditingController(text: _s('description'));
  late final genre = TextEditingController(text: _s('genre'));
  late final tags = TextEditingController(
      text: ((widget.existing?['tags'] as List?) ?? const []).join(', '));
  late final poster = TextEditingController(text: _s('poster'));
  late final free = TextEditingController(
      text: widget.existing?['freeEpisodes']?.toString() ?? '');
  late final pattern =
      TextEditingController(text: admin['pattern'] as String? ?? '');
  late final thumbPattern =
      TextEditingController(text: admin['thumbPattern'] as String? ?? '');
  final count = TextEditingController(text: '1');
  late String type = admin['type'] as String? ?? 'hls';
  bool addToFeed = true;
  bool idEdited = false;

  String _s(String k) => widget.existing?[k] as String? ?? '';

  @override
  void initState() {
    super.initState();
    if (isNew) title.addListener(_autoFill);
  }

  /// New series: id + URLs follow the title until the user edits the id.
  void _autoFill() {
    if (idEdited) return;
    final slug = title.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    setState(() {
      id.text = slug;
      _fillUrls(slug);
    });
  }

  void _fillUrls(String slug) {
    poster.text = '$_cdnBase/$slug/poster.jpg';
    pattern.text = type == 'hls'
        ? '$_cdnBase/$slug/ep-{n}/index.m3u8'
        : '$_cdnBase/$slug/ep-{n}.mp4';
  }

  Future<void> _save() async {
    final freeN = int.tryParse(free.text.trim());
    final eps = isNew
        ? ShortsController.generateEpisodes(
            from: 1,
            to: int.tryParse(count.text.trim()) ?? 0,
            type: type,
            pattern: pattern.text.trim(),
            thumbPattern: thumbPattern.text.trim(),
          )
        : c.episodesOf(_s('id'));
    if (pattern.text.trim().isNotEmpty && !pattern.text.contains('{n}')) {
      c.errorMessage.value = 'URL pattern must contain {n}.';
      return;
    }
    final data = <String, dynamic>{
      ...?widget.existing,
      'id': id.text.trim(),
      'title': title.text.trim(),
      'description': description.text.trim(),
      'genre': genre.text.trim(),
      'tags': tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      'poster': poster.text.trim(),
      'episodes': eps,
      '_admin': {
        'type': type,
        'pattern': pattern.text.trim(),
        'thumbPattern': thumbPattern.text.trim(),
      },
    };
    if (freeN == null) {
      data.remove('freeEpisodes');
    } else {
      data['freeEpisodes'] = freeN;
    }
    final ok = await c.saveSeries(data, isNew: isNew, addToFeed: isNew && addToFeed);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isNew ? 'Add series' : 'Edit series'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(title, 'Title *'),
              _field(id, 'ID * (lowercase_with_underscores — same as R2 folder)',
                  enabled: isNew, onChanged: (_) => idEdited = true),
              _field(description, 'Description', lines: 3),
              Row(children: [
                Expanded(child: _field(genre, 'Genre')),
                const SizedBox(width: 12),
                Expanded(child: _field(tags, 'Tags (comma separated)')),
              ]),
              _field(poster, 'Poster URL (vertical jpg)'),
              _field(free, 'Free episodes (empty = default from Settings)',
                  number: true),
              const Divider(height: 28),
              Row(
                children: [
                  const Text('Video type:  '),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'hls', label: Text('HLS (.m3u8)')),
                      ButtonSegment(value: 'mp4', label: Text('MP4')),
                    ],
                    selected: {type},
                    onSelectionChanged: (v) => setState(() {
                      type = v.first;
                      if (isNew && id.text.isNotEmpty) _fillUrls(id.text);
                    }),
                  ),
                ],
              ),
              _field(pattern, 'Episode URL pattern — {n} = episode number'),
              _field(thumbPattern,
                  'Episode thumbnail pattern (optional, e.g. .../ep-{n}.jpg)'),
              if (isNew) ...[
                _field(count, 'Number of episodes uploaded *', number: true),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: addToFeed,
                  onChanged: (v) => setState(() => addToFeed = v ?? true),
                  title: const Text('Show in app right away'),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Pattern changes apply to NEW episodes only. '
                    'Use "Edit episodes" to change existing ones.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
              Obx(() => c.errorMessage.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(c.errorMessage.value,
                          style: const TextStyle(color: Colors.red)),
                    )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            c.errorMessage.value = '';
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
              onPressed: c.isSaving.value ? null : _save,
              child: Text(c.isSaving.value ? 'Saving…' : 'Save'),
            )),
      ],
    );
  }
}

// ── Add new episodes ────────────────────────────────────────────────────────

class _ExtendDialog extends StatefulWidget {
  const _ExtendDialog({required this.id, required this.current});
  final String id;
  final int current;

  static Future<void> show(BuildContext context, String id, int current) =>
      showDialog(
        context: context,
        builder: (_) => _ExtendDialog(id: id, current: current),
      );

  @override
  State<_ExtendDialog> createState() => _ExtendDialogState();
}

class _ExtendDialogState extends State<_ExtendDialog> {
  final c = Get.find<ShortsController>();
  late final upTo = TextEditingController(text: '${widget.current + 1}');

  @override
  Widget build(BuildContext context) {
    final admin = c.series[widget.id]?['_admin'] as Map?;
    return AlertDialog(
      title: const Text('Add new episodes'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Currently ${widget.current} episodes.'),
            const SizedBox(height: 4),
            Text('Pattern: ${admin?['pattern'] ?? '(none — edit series first)'}',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            _field(upTo, 'Add episodes up to number', number: true),
            Obx(() => Text(c.errorMessage.value,
                style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        Obx(() => ElevatedButton(
              onPressed: c.isSaving.value
                  ? null
                  : () async {
                      final n = int.tryParse(upTo.text.trim()) ?? 0;
                      final ok = await c.extendEpisodes(widget.id, n);
                      if (ok && context.mounted) Navigator.pop(context);
                    },
              child: Text(c.isSaving.value ? 'Saving…' : 'Add'),
            )),
      ],
    );
  }
}

// ── Edit episodes ───────────────────────────────────────────────────────────

class _EpisodesDialog extends StatelessWidget {
  const _EpisodesDialog({required this.id});
  final String id;

  static Future<void> show(BuildContext context, String id) => showDialog(
        context: context,
        builder: (_) => _EpisodesDialog(id: id),
      );

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ShortsController>();
    return AlertDialog(
      title: Text('Episodes — ${c.series[id]?['title'] ?? id}'),
      content: SizedBox(
        width: 640,
        height: 520,
        child: Obx(() {
          final eps = c.episodesOf(id);
          return ListView.separated(
            itemCount: eps.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = eps[i];
              final url = (e['hls'] ?? e['mp4'] ?? '') as String;
              final locked = e['locked'];
              return ListTile(
                dense: true,
                leading: CircleAvatar(radius: 14, child: Text('${e['n']}')),
                title: Text(e['title'] as String? ?? ''),
                subtitle: Text(url,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (locked != null)
                      _Pill(
                        text: locked == true ? 'LOCKED' : 'FREE',
                        color: locked == true ? Colors.orange : Colors.green,
                      ),
                    IconButton(
                      tooltip: 'Copy URL',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: url)),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _EpisodeEditDialog.show(context, id, e),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      onPressed: () async {
                        final ok = await showConfirmDialog(context,
                            'Delete episode ${e['n']}?', 'This cannot be undone.');
                        if (ok) c.deleteEpisode(id, e['n'] as int);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

class _EpisodeEditDialog extends StatefulWidget {
  const _EpisodeEditDialog({required this.id, required this.episode});
  final String id;
  final Map<String, dynamic> episode;

  static Future<void> show(
          BuildContext context, String id, Map<String, dynamic> ep) =>
      showDialog(
        context: context,
        builder: (_) => _EpisodeEditDialog(id: id, episode: ep),
      );

  @override
  State<_EpisodeEditDialog> createState() => _EpisodeEditDialogState();
}

class _EpisodeEditDialogState extends State<_EpisodeEditDialog> {
  final c = Get.find<ShortsController>();
  late final title =
      TextEditingController(text: widget.episode['title'] as String? ?? '');
  late final hls =
      TextEditingController(text: widget.episode['hls'] as String? ?? '');
  late final mp4 =
      TextEditingController(text: widget.episode['mp4'] as String? ?? '');
  late final thumb =
      TextEditingController(text: widget.episode['thumb'] as String? ?? '');
  late String lock = switch (widget.episode['locked']) {
    true => 'locked',
    false => 'free',
    _ => 'auto',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Episode ${widget.episode['n']}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(title, 'Title'),
            _field(hls, 'HLS URL (.m3u8)'),
            _field(mp4, 'MP4 URL (fallback / alternative)'),
            _field(thumb, 'Thumbnail URL (optional)'),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'auto', label: Text('Auto (free count)')),
                ButtonSegment(value: 'free', label: Text('Always free')),
                ButtonSegment(value: 'locked', label: Text('Always locked')),
              ],
              selected: {lock},
              onSelectionChanged: (v) => setState(() => lock = v.first),
            ),
            Obx(() => Text(c.errorMessage.value,
                style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        Obx(() => ElevatedButton(
              onPressed: c.isSaving.value
                  ? null
                  : () async {
                      final ep = <String, dynamic>{
                        'n': widget.episode['n'],
                        'title': title.text.trim(),
                        if (hls.text.trim().isNotEmpty) 'hls': hls.text.trim(),
                        if (mp4.text.trim().isNotEmpty) 'mp4': mp4.text.trim(),
                        if (thumb.text.trim().isNotEmpty)
                          'thumb': thumb.text.trim(),
                        if (lock != 'auto') 'locked': lock == 'locked',
                      };
                      final ok = await c.saveEpisode(widget.id, ep);
                      if (ok && context.mounted) Navigator.pop(context);
                    },
              child: Text(c.isSaving.value ? 'Saving…' : 'Save'),
            )),
      ],
    );
  }
}

// ═══ Settings tab ════════════════════════════════════════════════════════════

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final c = Get.find<ShortsController>();
  late bool enabled = c.enabled;
  late int maxPlayers = (c.config['max_players'] as num?)?.toInt() ?? 3;
  late final freeDefault =
      TextEditingController(text: '${c.config['free_episodes_default'] ?? 10}');
  late final Map<String, dynamic> ads = c.ads;
  late final everyN = TextEditingController(
      text: '${ads['interstitial_every_n_episodes'] ?? 4}');
  late final firstAfter =
      TextEditingController(text: '${ads['interstitial_first_after'] ?? 3}');
  late final perAd =
      TextEditingController(text: '${ads['unlock_episodes_per_ad'] ?? 3}');
  late bool interEnabled = ads['interstitial_enabled'] != false;
  late bool rewardEnabled = ads['rewarded_unlock_enabled'] != false;
  late bool unlockOnNoFill = ads['unlock_on_no_fill'] == true;

  int _n(TextEditingController t, int min) =>
      (int.tryParse(t.text.trim()) ?? min).clamp(min, 1000);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _card('General', [
          SwitchListTile(
            title: const Text('Shorts enabled (shows the Shorts tab in the app)'),
            subtitle: const Text(
                'When off, the app looks exactly like before (Downloads tab stays).'),
            value: enabled,
            onChanged: (v) => setState(() => enabled = v),
          ),
          _field(freeDefault,
              'Free episodes per series (default — each series can override)',
              number: true),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Video players in memory:  '),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 3, label: Text('3 (smoothest)')),
                ButtonSegment(value: 2, label: Text('2 (low-RAM phones)')),
              ],
              selected: {maxPlayers},
              onSelectionChanged: (v) => setState(() => maxPlayers = v.first),
            ),
          ]),
        ]),
        _card('Interstitial ads (between episodes)', [
          SwitchListTile(
            title: const Text('Enabled'),
            value: interEnabled,
            onChanged: (v) => setState(() => interEnabled = v),
          ),
          Row(children: [
            Expanded(child: _field(everyN, 'Show every N episodes', number: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _field(firstAfter, 'No ads for first N episodes',
                    number: true)),
          ]),
          const _Hint('Also needs "Shorts Feed" turned on in Ads → Interstitial '
              'screens. Global cooldown / max per session still apply.'),
        ]),
        _card('Rewarded ads (unlock locked episodes)', [
          SwitchListTile(
            title: const Text('Lock episodes after the free ones'),
            subtitle: const Text('Off = every episode is free.'),
            value: rewardEnabled,
            onChanged: (v) => setState(() => rewardEnabled = v),
          ),
          _field(perAd, 'Episodes unlocked per ad', number: true),
          SwitchListTile(
            title: const Text('Unlock anyway when no ad is available'),
            value: unlockOnNoFill,
            onChanged: (v) => setState(() => unlockOnNoFill = v),
          ),
          const _Hint('Also needs "Shorts Unlock" turned on in Ads → Rewarded screens.'),
        ]),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Obx(() => ElevatedButton.icon(
                onPressed: c.isSaving.value
                    ? null
                    : () async {
                        final ok = await c.saveSettings(
                          fields: {
                            'enabled': enabled,
                            'free_episodes_default': _n(freeDefault, 0),
                            'max_players': maxPlayers,
                          },
                          adFields: {
                            'interstitial_enabled': interEnabled,
                            'interstitial_every_n_episodes': _n(everyN, 1),
                            'interstitial_first_after': _n(firstAfter, 0),
                            'rewarded_unlock_enabled': rewardEnabled,
                            'unlock_episodes_per_ad': _n(perAd, 1),
                            'unlock_on_no_fill': unlockOnNoFill,
                          },
                        );
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Shorts settings saved')),
                          );
                        }
                      },
                icon: const Icon(Icons.save),
                label: Text(c.isSaving.value ? 'Saving…' : 'Save settings'),
              )),
        ),
      ],
    );
  }

  Widget _card(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      );
}

// ═══ Shared bits ═════════════════════════════════════════════════════════════

Widget _field(
  TextEditingController controller,
  String label, {
  bool number = false,
  bool enabled = true,
  int lines = 1,
  ValueChanged<String>? onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: controller,
      enabled: enabled,
      maxLines: lines,
      onChanged: onChanged,
      keyboardType: number ? TextInputType.number : null,
      inputFormatters:
          number ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text,
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
      );
}
