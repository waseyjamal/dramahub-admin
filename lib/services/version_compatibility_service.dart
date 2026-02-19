import '../core/constants/version_constants.dart';

class VersionCheckResult {
  final bool allowed;
  final bool forceUpdate;
  final String message;

  VersionCheckResult({
    required this.allowed,
    required this.forceUpdate,
    required this.message,
  });
}

class VersionCompatibilityService {
  VersionCheckResult checkAdminCompatibility(Map<String, dynamic> config) {
    final minVersion = config['min_admin_version'] ?? 1;
    final latestVersion = config['latest_admin_version'] ?? 1;
    final forceUpdate = config['force_update_admin'] ?? false;

    final current = VersionConstants.adminVersion;

    if (current < minVersion) {
      return VersionCheckResult(
        allowed: false,
        forceUpdate: true,
        message: 'Admin version too old. Minimum required: $minVersion',
      );
    }

    if (forceUpdate) {
      return VersionCheckResult(
        allowed: false,
        forceUpdate: true,
        message: 'Admin update required by system policy.',
      );
    }

    if (current < latestVersion) {
      return VersionCheckResult(
        allowed: true,
        forceUpdate: false,
        message: 'New admin version available ($latestVersion).',
      );
    }

    return VersionCheckResult(
      allowed: true,
      forceUpdate: false,
      message: 'Admin version compatible.',
    );
  }

  VersionCheckResult checkUserCompatibility(
      Map<String, dynamic> config, int userVersion) {
    final minVersion = config['min_user_version'] ?? 1;
    final latestVersion = config['latest_user_version'] ?? 1;
    final forceUpdate = config['force_update_user'] ?? false;

    if (userVersion < minVersion) {
      return VersionCheckResult(
        allowed: false,
        forceUpdate: true,
        message: 'User app version too old. Minimum required: $minVersion',
      );
    }

    if (forceUpdate) {
      return VersionCheckResult(
        allowed: false,
        forceUpdate: true,
        message: 'User app force update enabled.',
      );
    }

    if (userVersion < latestVersion) {
      return VersionCheckResult(
        allowed: true,
        forceUpdate: false,
        message: 'User update available ($latestVersion).',
      );
    }

    return VersionCheckResult(
      allowed: true,
      forceUpdate: false,
      message: 'User version compatible.',
    );
  }

  bool isSchemaCompatible(int configSchemaVersion, int supportedSchemaVersion) {
    return configSchemaVersion <= supportedSchemaVersion;
  }
}
