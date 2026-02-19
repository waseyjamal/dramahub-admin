import 'dramahub_exception.dart';

class ConflictException extends DramaHubException {
  ConflictException()
      : super(
          'File was modified by another user.',
          code: 'CONFLICT',
        );
}
