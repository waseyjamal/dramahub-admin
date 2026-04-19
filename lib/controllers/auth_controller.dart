import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/github_service.dart';
import '../services/version_compatibility_service.dart';
import '../services/admin_log_service.dart';
import '../controllers/config_controller.dart';
import '../data/repositories/github_repository.dart';

class AuthController extends GetxController with WidgetsBindingObserver {
  final StorageService _storage = Get.find();
  late final AuthService _authService;
  final GitHubService _githubService = Get.find();

  final RxBool isAuthenticated = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _authService = AuthService(_storage);

    // Platform-specific startup logic
    if (!kIsWeb) {
      // Requirement 5 for Android: If onInit runs, the app was fully closed.
      // Always require password on fresh startup.
      _storage.clearSession();
      _storage.clearPauseTimestamp();
    }

    isAuthenticated.value = _storage.isLoggedIn();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;

    if (state == AppLifecycleState.detached) {
      // Clear session flag on full close
      _storage.clearSession();
      _storage.clearPauseTimestamp();
      isAuthenticated.value = false;
    } else if (state == AppLifecycleState.paused) {
      // Safety net: record when we were last active
      _storage.savePauseTimestamp();
    }
  }

  void checkTokenRotation() {
    final created = _storage.getTokenCreatedAt();
    if (created == null) return;

    final createdDate = DateTime.parse(created);
    if (DateTime.now().difference(createdDate).inDays > 90) {
      errorMessage.value =
          'GitHub PAT older than 90 days. Please rotate your token.';
    }
  }

  Future<bool> login(String password, String token) async {
    final valid = await _authService.validatePassword(password);

    if (!valid) {
      errorMessage.value = 'Invalid password or account locked.';
      return false;
    }

    await _storage.saveToken(token, password);
    await _storage.saveSession(true);
    _githubService.setAuthToken(token);

    try {
      final configController = Get.find<ConfigController>();
      final versionService = Get.find<VersionCompatibilityService>();
      final result =
          versionService.checkAdminCompatibility(configController.config);

      if (!result.allowed) {
        errorMessage.value = result.message;
        return false;
      }
    } catch (_) {
      // Config not loaded yet — skip version check
    }

    isAuthenticated.value = true;
    checkTokenRotation();

    try {
      Get.find<AdminLogService>().record('Admin logged in');
    } catch (_) {}

    return true;
  }

  /// Lock just clears the current session flag without deleting the stored PAT.
  Future<void> lock() async {
    await _storage.clearSession();
    isAuthenticated.value = false;

    try {
      Get.find<AdminLogService>().record('Admin session locked');
    } catch (_) {}
  }

  Future<void> logout() async {
    await _storage.clearToken();
    await _storage.clearSession();
    await _storage.clearPauseTimestamp();
    isAuthenticated.value = false;

    try {
      Get.find<GitHubRepository>().clearCache();
    } catch (_) {}

    try {
      Get.find<AdminLogService>().logs.clear();
      Get.find<AdminLogService>().record('Admin logged out');
    } catch (_) {}
  }
}
