class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, required this.errors});
}

class ValidationService {
  ValidationResult validateEpisode(Map<String, dynamic> json) {
    final errors = <String>[];

    if (json['id'] == null || json['id'].toString().isEmpty) {
      errors.add('Episode ID is required.');
    }

    if (json['dramaId'] == null || json['dramaId'].toString().isEmpty) {
      errors.add('dramaId is required.');
    }

    final isCustom = json['playerType'] == 'custom';
    if (isCustom) {
      // ✅ Either streamUrl OR mp4Url is acceptable for custom player
      final hasStream = json['streamUrl'] != null &&
          json['streamUrl'].toString().isNotEmpty;
      final hasMp4 = json['mp4Url'] != null &&
          json['mp4Url'].toString().isNotEmpty;
      if (!hasStream && !hasMp4) {
        errors.add(
            'Custom player requires either streamUrl (HLS) or mp4Url (MP4).');
      }
    } else {
      if (json['videoId'] == null || json['videoId'].toString().isEmpty) {
        errors.add('videoId is required.');
      }
    }

    if (json['episodeNumber'] == null || json['episodeNumber'] < 1) {
      errors.add('episodeNumber must be >= 1.');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  ValidationResult validateDrama(Map<String, dynamic> json) {
    final errors = <String>[];

    if (json['id'] == null || json['id'].toString().isEmpty) {
      errors.add('Drama ID is required.');
    }

    if (json['title'] == null || json['title'].toString().isEmpty) {
      errors.add('Drama title is required.');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
