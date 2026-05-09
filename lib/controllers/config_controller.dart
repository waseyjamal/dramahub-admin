import 'package:get/get.dart';
import '../data/repositories/github_repository.dart';
import '../services/github_service.dart';

class ConfigController extends GetxController {
  final GitHubRepository _repository =
      GitHubRepository(Get.find<GitHubService>());

  final RxMap<String, dynamic> config = <String, dynamic>{}.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  static const String _path = 'app_config.json';

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  Future<void> loadConfig() async {
    try {
      isLoading.value = true;
      final data = await _repository.fetchJsonList(_path);
      config.assignAll(Map<String, dynamic>.from(data));
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateField(String key, dynamic value) async {
    // Convert String input to correct type based on existing config value
    final existing = config[key];
    dynamic typedValue = value;

    if (value is String) {
      if (existing is bool) {
        typedValue = value.toLowerCase() == 'true';
      } else if (existing is int) {
        typedValue = int.tryParse(value) ?? existing;
      } else if (existing is double) {
        typedValue = double.tryParse(value) ?? existing;
      }
    }

    config[key] = typedValue;
    config.refresh();
    await _commit('Update config: $key');
  }

  Future<void> _commit(String message) async {
    await _repository.commitJsonList(
      path: _path,
      data: config,
      message: message,
    );
  }
}
