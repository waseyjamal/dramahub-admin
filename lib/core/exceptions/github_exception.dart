import 'dramahub_exception.dart';

class GitHubApiException extends DramaHubException {
  final int statusCode;

  GitHubApiException(super.message, this.statusCode)
      : super.new(code: 'GITHUB_$statusCode');
}
