import 'dart:async';
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/github_service.dart';
import '../services/version_compatibility_service.dart';
import '../services/admin_log_service.dart';
import '../controllers/config_controller.dart';
import '../data/repositories/github_repository.dart';

class AuthController extends GetxController {
  final StorageService _storage = Get.find();
  late final AuthService _authService;
  final GitHubService _githubService = Get.find();

  final RxBool isAuthenticated = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DateTime?> lastActivity = Rx<DateTime?>(null);

  static const Duration sessionTimeout = Duration(minutes: 30);
  Timer? _idleTimer;

  @override
  void onInit() {
    super.onInit();
    _authService = AuthService(_storage);
    isAuthenticated.value = _storage.isLoggedIn();
  }

  void startSessionTimer() {
    _resetTimer();
  }

  void registerActivity() {
    lastActivity.value = DateTime.now();
    _resetTimer();
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(sessionTimeout, () async {
      await logout();
    });
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
    startSessionTimer();
    checkTokenRotation();

    try {
      Get.find<AdminLogService>().record('Admin logged in');
    } catch (_) {}

    return true;
  }

  Future<void> logout() async {
    _idleTimer?.cancel();
    await _storage.clearToken();
    await _storage.clearSession();
    isAuthenticated.value = false;

    try {
      Get.find<GitHubRepository>().clearCache();
    } catch (_) {}

    try {
      Get.find<AdminLogService>().logs.clear();
    } catch (_) {}
  }
}
