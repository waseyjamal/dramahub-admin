abstract class DramaHubException implements Exception {
  final String message;
  final String? code;

  DramaHubException(this.message, {this.code});

  @override
  String toString() => message;
}
