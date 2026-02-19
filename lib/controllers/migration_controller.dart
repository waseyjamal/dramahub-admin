import 'package:get/get.dart';
import '../controllers/config_controller.dart';
import '../core/migration/json_migration_engine.dart';
import '../services/github_service.dart';
import '../data/repositories/github_repository.dart';

class MigrationController extends GetxController {
  final ConfigController _configController = Get.find();
  final GitHubRepository _repository =
      GitHubRepository(Get.find<GitHubService>());

  final RxBool migrationNeeded = false.obs;
  final RxString migrationMessage = ''.obs;

  void checkMigration() {
    final version = _configController.config['schema_version'] ?? 1;

    if (JsonMigrationEngine.needsMigration(version)) {
      migrationNeeded.value = true;
      migrationMessage.value =
          'Migration required: v$version → v${JsonMigrationEngine.currentSchemaVersion}';
    }
  }

  Future<void> runMigration() async {
    final currentConfig = Map<String, dynamic>.from(_configController.config);

    final migrated = JsonMigrationEngine.migrateConfig(currentConfig);

    await _repository.commitJsonList(
      path: 'app_config.json',
      data: currentConfig,
      message: 'Backup before migration',
    );

    await _repository.commitJsonList(
      path: 'app_config.json',
      data: migrated,
      message:
          'Migrate schema v${currentConfig['schema_version']} → ${migrated['schema_version']}',
    );

    _configController.config.assignAll(migrated);
    migrationNeeded.value = false;
  }
}
