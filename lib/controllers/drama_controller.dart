import 'package:get/get.dart';
import '../services/validation_service.dart';
import '../services/admin_log_service.dart';
import '../data/repositories/github_repository.dart';
import '../services/github_service.dart';

class DramaController extends GetxController {
  final GitHubRepository _repository =
      GitHubRepository(Get.find<GitHubService>());
  final ValidationService _validator = Get.find();

  final RxList<Map<String, dynamic>> dramas = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  static const String _path = 'dramas.json';

  @override
  void onInit() {
    super.onInit();
    loadDramas();
  }

  Future<void> loadDramas() async {
    try {
      isLoading.value = true;
      final data = await _repository.fetchJsonList(_path);
      dramas.assignAll(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addDrama(Map<String, dynamic> drama) async {
    final validation = _validator.validateDrama(drama);
    if (!validation.isValid) {
      errorMessage.value = validation.errors.join('\n');
      return;
    }

    dramas.add(drama);
    await _commit('Add drama: ${drama['title']}');

    try {
      Get.find<AdminLogService>().record('Added drama: ${drama['title']}');
    } catch (_) {}
  }

  Future<void> updateDrama(int index, Map<String, dynamic> updated) async {
    final validation = _validator.validateDrama(updated);
    if (!validation.isValid) {
      errorMessage.value = validation.errors.join('\n');
      return;
    }

    dramas[index] = updated;
    await _commit('Update drama: ${updated['title']}');

    try {
      Get.find<AdminLogService>().record('Updated drama: ${updated['title']}');
    } catch (_) {}
  }

  Future<void> deleteDrama(int index) async {
    final title = dramas[index]['title'];
    dramas.removeAt(index);
    await _commit('Delete drama: $title');

    try {
      Get.find<AdminLogService>().record('Deleted drama: $title');
    } catch (_) {}
  }

  Future<void> toggleActive(int index) async {
    dramas[index]['isActive'] = !(dramas[index]['isActive'] ?? true);
    dramas.refresh();
    await _commit('Toggle active: ${dramas[index]['title']}');
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final item = dramas.removeAt(oldIndex);
    dramas.insert(newIndex, item);

    for (int i = 0; i < dramas.length; i++) {
      dramas[i]['order'] = i;
    }

    dramas.refresh();
    await _commit('Reorder dramas');
  }

  Future<void> updateTotalEpisodes(String dramaId, int count) async {
    final index = dramas.indexWhere((d) => d['id'] == dramaId);
    if (index == -1) return;

    dramas[index]['totalEpisodes'] = count;
    dramas.refresh();
    await _commit('Sync totalEpisodes for $dramaId');
  }

  Future<void> _commit(String message) async {
    await _repository.commitJsonList(
      path: _path,
      data: dramas,
      message: message,
    );
  }
}
