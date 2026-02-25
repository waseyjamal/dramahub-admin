import 'package:get/get.dart';
import '../services/github_service.dart';
import '../services/version_compatibility_service.dart';
import '../controllers/drama_controller.dart';
import '../controllers/episode_controller.dart';
import '../controllers/config_controller.dart';

class DashboardController extends GetxController {
  final GitHubService _githubService = Get.find();
  final DramaController _dramaController = Get.find();
  final EpisodeController _episodeController = Get.find();

  final RxInt totalDramas = 0.obs;
  final RxInt totalEpisodes = 0.obs;

  final RxBool isConnected = false.obs;
  final RxInt rateRemaining = 0.obs;
  final RxInt rateLimit = 0.obs;

  final RxString versionStatus = ''.obs;
  final RxInt apiLatency = 0.obs;
  final RxString systemHealth = ''.obs;

  final RxList<Map<String, dynamic>> recentCommits =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshStats();
  }

  Future<void> refreshStats() async {
    totalDramas.value = _dramaController.dramas.length;
    totalEpisodes.value = _episodeController.episodes.length;

    await _githubService.testConnection();

    isConnected.value = _githubService.isConnected.value;
    rateRemaining.value = _githubService.rateLimitRemaining.value;
    rateLimit.value = _githubService.rateLimitLimit.value;
    apiLatency.value = _githubService.apiLatencyMs.value;

    _updateSystemHealth();

    // Load analytics in parallel

    try {
      final commits = await _githubService.fetchRecentCommits();
      recentCommits.assignAll(
        commits
            .map<Map<String, dynamic>>((c) => {
                  'message': c['commit']['message'],
                  'author': c['commit']['author']['name'],
                  'date': c['commit']['author']['date'],
                })
            .toList(),
      );
    } catch (_) {}

    try {
      final versionService = Get.find<VersionCompatibilityService>();
      final configController = Get.find<ConfigController>();
      final result =
          versionService.checkAdminCompatibility(configController.config);
      versionStatus.value = result.message;
    } catch (_) {
      versionStatus.value = 'Version check unavailable.';
    }
  }

  void _updateSystemHealth() {
    if (!_githubService.isConnected.value) {
      systemHealth.value = 'CRITICAL – GitHub Offline';
      return;
    }
    if (_githubService.rateLimitRemaining.value < 20) {
      systemHealth.value = 'WARNING – Low API Rate Limit';
      return;
    }
    if (apiLatency.value > 2000) {
      systemHealth.value = 'WARNING – High API Latency';
      return;
    }
    systemHealth.value = 'HEALTHY';
  }
}
