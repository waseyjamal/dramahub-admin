import 'package:dramahub_admin/controllers/ad_controller.dart';
import 'package:get/get.dart';

import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../services/validation_service.dart';
import '../services/version_compatibility_service.dart';
import '../services/admin_log_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/drama_controller.dart';
import '../controllers/episode_controller.dart';
import '../controllers/config_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/migration_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<GitHubService>(GitHubService(), permanent: true);
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<ValidationService>(ValidationService(), permanent: true);
    Get.put<VersionCompatibilityService>(VersionCompatibilityService(),
        permanent: true);
    Get.put<AdminLogService>(AdminLogService(), permanent: true);
    Get.lazyPut<AdController>(() => AdController());

    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<DramaController>(() => DramaController());
    Get.lazyPut<EpisodeController>(() => EpisodeController());
    Get.lazyPut<ConfigController>(() => ConfigController());

    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<MigrationController>(() => MigrationController());
  }
}
