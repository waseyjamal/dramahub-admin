import 'dramahub_exception.dart';

class GitHubApiException extends DramaHubException {
  final int statusCode;

  GitHubApiException(String message, this.statusCode)
      : super(message, code: 'GITHUB_$statusCode');
}
