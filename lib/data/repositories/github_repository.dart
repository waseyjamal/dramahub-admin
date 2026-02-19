import 'dart:convert';
import '../../services/github_service.dart';
import '../cache/memory_cache.dart';

class GitHubRepository {
  final GitHubService _service;
  final MemoryCache _cache = MemoryCache();

  GitHubRepository(this._service);

  Future<dynamic> fetchJsonList(String path) async {
    final cached = _cache.get(path);
    if (cached != null) {
      return cached;
    }

    final file = await _service.fetchFile(path);
    final decoded = jsonDecode(file.decodedContent);

    Duration duration = const Duration(minutes: 5);

    if (path.contains('episodes/')) {
      duration = const Duration(minutes: 2);
    }

    if (path == 'app_config.json') {
      duration = const Duration(minutes: 10);
    }

    _cache.set(path, decoded, duration);

    return decoded;
  }

  Future<void> commitJsonList({
    required String path,
    required dynamic data,
    required String message,
  }) async {
    final content = jsonEncode(data);

    if (content.trim().isEmpty) {
      throw Exception('Empty JSON not allowed.');
    }

    await _service.commitWithRetry(
      path: path,
      newContent: content,
      message: message,
    );

    _cache.invalidate(path);
  }

  Future<void> batchCommit(
    Map<String, dynamic> files,
    String message,
  ) async {
    for (final entry in files.entries) {
      await commitJsonList(
        path: entry.key,
        data: entry.value,
        message: '$message (${entry.key})',
      );
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
