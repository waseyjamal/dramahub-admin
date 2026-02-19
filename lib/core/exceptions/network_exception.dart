import 'dramahub_exception.dart';

class NetworkException extends DramaHubException {
  NetworkException()
      : super(
          'Network error. Please check your connection.',
          code: 'NETWORK',
        );
}
