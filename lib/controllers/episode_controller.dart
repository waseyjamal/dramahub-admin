import 'package:get/get.dart';
import '../services/validation_service.dart';
import '../data/repositories/github_repository.dart';
import '../services/github_service.dart';
import 'drama_controller.dart';

class EpisodeController extends GetxController {
  final GitHubRepository _repository =
      GitHubRepository(Get.find<GitHubService>());
  final ValidationService _validator = Get.find();
  final DramaController _dramaController = Get.find();

  final RxList<Map<String, dynamic>> episodes = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  String? currentDramaId;
  int currentSeason = 1;

  static const int pageSize = 20;
  final RxInt currentPage = 0.obs;

  String _seasonPath(String dramaId, int season) {
    return 'episodes/$dramaId/season_$season.json';
  }

  List<Map<String, dynamic>> get paginatedEpisodes {
    final start = currentPage.value * pageSize;
    return episodes.skip(start).take(pageSize).toList();
  }

  Future<void> loadEpisodes(
    String dramaId, {
    int season = 1,
  }) async {
    currentDramaId = dramaId;
    currentSeason = season;
    final path = _seasonPath(dramaId, season);

    try {
      isLoading.value = true;
      final data = await _repository.fetchJsonList(path);
      episodes.assignAll(List<Map<String, dynamic>>.from(data));
      _sortDescending();
    } catch (e) {
      // Fallback to flat path for backward compatibility
      try {
        final fallbackPath = 'episodes/$dramaId.json';
        final data = await _repository.fetchJsonList(fallbackPath);
        episodes.assignAll(List<Map<String, dynamic>>.from(data));
        _sortDescending();
      } catch (e2) {
        errorMessage.value = e2.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addEpisode(Map<String, dynamic> episode) async {
    if (currentDramaId == null) return;

    episode['id'] = '${currentDramaId}_ep_${episode['episodeNumber']}';

    final validation = _validator.validateEpisode(episode);
    if (!validation.isValid) {
      errorMessage.value = validation.errors.join('\n');
      return;
    }

    episodes.add(episode);
    _sortDescending();
    await _commit('Add episode ${episode['episodeNumber']}');
    _syncTotal();
  }

  Future<void> updateEpisode(int index, Map<String, dynamic> updated) async {
    final validation = _validator.validateEpisode(updated);
    if (!validation.isValid) {
      errorMessage.value = validation.errors.join('\n');
      return;
    }

    episodes[index] = updated;
    _sortDescending();
    await _commit('Update episode ${updated['episodeNumber']}');
  }

  Future<void> deleteEpisode(int index) async {
    final number = episodes[index]['episodeNumber'];
    episodes.removeAt(index);
    await _commit('Delete episode $number');
    _syncTotal();
  }

  void _sortDescending() {
    episodes.sort((a, b) => b['episodeNumber'].compareTo(a['episodeNumber']));
    episodes.refresh();
  }

  Future<void> _commit(String message) async {
    final path = _seasonPath(currentDramaId!, currentSeason);
    await _repository.commitJsonList(
      path: path,
      data: episodes,
      message: message,
    );
  }

  void _syncTotal() {
    if (currentDramaId == null) return;
    _dramaController.updateTotalEpisodes(currentDramaId!, episodes.length);
  }
}
