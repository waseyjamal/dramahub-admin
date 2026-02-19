import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../core/constants/api_constants.dart';
import '../core/exceptions/github_exception.dart';
import '../core/exceptions/conflict_exception.dart';
import '../core/exceptions/network_exception.dart';
import '../data/models/github_file_model.dart';

class GitHubService extends GetxService {
  final Dio _dio = Dio();

  final RxBool isConnected = true.obs;
  final RxInt rateLimitRemaining = 0.obs;
  final RxInt rateLimitLimit = 0.obs;
  final RxInt apiLatencyMs = 0.obs;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'token $token';
  }

  Future<void> safeDelayIfLowRate() async {
    if (rateLimitRemaining.value < 10) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> testConnection() async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.get(
        '${ApiConstants.githubApiBase}/rate_limit',
      );

      stopwatch.stop();
      apiLatencyMs.value = stopwatch.elapsedMilliseconds;

      rateLimitRemaining.value = response.data['rate']['remaining'];
      rateLimitLimit.value = response.data['rate']['limit'];

      isConnected.value = true;
    } catch (_) {
      stopwatch.stop();
      apiLatencyMs.value = -1;
      isConnected.value = false;
      rethrow;
    }
  }

  Future<List<dynamic>> fetchRecentCommits({
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.githubApiBase}/repos/${ApiConstants.githubOwner}/${ApiConstants.githubRepo}/commits',
      queryParameters: {'per_page': limit},
    );
    return response.data;
  }

  Future<GitHubFileModel> fetchFile(String path) async {
    try {
      final response = await _dio.get(
        ApiConstants.contentsUrl(path),
        queryParameters: {'ref': ApiConstants.githubBranch},
      );
      return GitHubFileModel.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<void> updateFile({
    required String path,
    required String content,
    required String sha,
    required String message,
  }) async {
    try {
      final encodedContent = base64Encode(utf8.encode(content));
      await _dio.put(
        ApiConstants.contentsUrl(path),
        data: {
          'message': message,
          'content': encodedContent,
          'sha': sha,
          'branch': ApiConstants.githubBranch,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw ConflictException();
      }
      _handleDioError(e);
      rethrow;
    }
  }

  Future<void> commitWithRetry({
    required String path,
    required String newContent,
    required String message,
    int maxAttempts = 3,
  }) async {
    await safeDelayIfLowRate();
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        final file = await fetchFile(path);
        await updateFile(
          path: path,
          content: newContent,
          sha: file.sha,
          message: message,
        );
        return;
      } on ConflictException {
        attempts++;
        if (attempts >= maxAttempts) {
          throw ConflictException();
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> createBackupCommit(
    String path,
    String content,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await commitWithRetry(
      path: path,
      newContent: content,
      message: 'Backup before migration [$timestamp]',
    );
  }

  Future<String> fetchRawFileBySha(
    String path,
    String sha,
  ) async {
    final response = await _dio.get(
      ApiConstants.contentsUrl(path),
      queryParameters: {'ref': sha},
    );
    return response.data['content'];
  }

  Future<void> deleteFile({
    required String path,
    required String sha,
    required String message,
  }) async {
    try {
      await _dio.delete(
        ApiConstants.contentsUrl(path),
        data: {
          'message': message,
          'sha': sha,
          'branch': ApiConstants.githubBranch,
        },
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  void _handleDioError(DioException e) {
    if (e.response?.statusCode == 403 &&
        e.response?.data.toString().contains('rate limit') == true) {
      throw GitHubApiException('GitHub rate limit exceeded.', 403);
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      throw NetworkException();
    }

    if (e.response != null) {
      throw GitHubApiException(
        e.response?.data.toString() ?? 'GitHub API Error',
        e.response!.statusCode ?? 500,
      );
    }

    throw NetworkException();
  }
}
