import 'package:dio/dio.dart';
import '../exceptions/dramahub_exception.dart';
import '../exceptions/github_exception.dart';
import '../exceptions/network_exception.dart';
import '../exceptions/conflict_exception.dart';

class ErrorHandler {
  static String resolve(Object error) {
    if (error is ConflictException) {
      return 'Conflict detected. File modified elsewhere.';
    }

    if (error is NetworkException) {
      return 'No internet connection.';
    }

    if (error is GitHubApiException) {
      return error.message;
    }

    if (error is DioException) {
      return 'Network request failed.';
    }

    if (error is DramaHubException) {
      return error.message;
    }

    return 'Unexpected error occurred.';
  }
}
