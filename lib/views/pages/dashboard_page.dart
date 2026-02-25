import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/drama_controller.dart';
import '../../controllers/episode_controller.dart';
import '../../services/admin_log_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static Future<void> _openAnalytics() async {
    final url = Uri.parse(
      'https://console.firebase.google.com/project/dramahub-81508/analytics/app/android:com.dramahub.drama_hub/overview',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final dramaController = Get.find<DramaController>();
    final episodeController = Get.find<EpisodeController>();
    final logService = Get.find<AdminLogService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Obx(() {
        final health = controller.systemHealth.value;
        final isHealthy = health == 'HEALTHY';

        return RefreshIndicator(
          onRefresh: controller.refreshStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ─── Health Card ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHealthy
                          ? [Colors.green.shade400, Colors.green.shade700]
                          : [Colors.red.shade400, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isHealthy ? Icons.check_circle : Icons.warning_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            health.isEmpty ? 'Checking...' : health,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'API Latency: ${controller.apiLatency} ms',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: controller.refreshStats,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Stats Row ───────────────────────────────────────
                Row(
                  children: [
                    _statCard('Dramas', '${dramaController.dramas.length}',
                        Icons.movie, Colors.deepPurple),
                    const SizedBox(width: 12),
                    _statCard(
                        'Episodes',
                        '${episodeController.episodes.length}',
                        Icons.play_circle,
                        Colors.blue),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statCard(
                        'Rate Limit',
                        '${controller.rateRemaining}/${controller.rateLimit}',
                        Icons.speed,
                        Colors.orange),
                    const SizedBox(width: 12),
                    _statCard(
                        'GitHub',
                        controller.isConnected.value ? 'Connected' : 'Offline',
                        Icons.cloud,
                        controller.isConnected.value
                            ? Colors.green
                            : Colors.red),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── Analytics Section ───────────────────────────────
                const _SectionTitle(
                  title: 'User Analytics',
                  icon: Icons.analytics_rounded,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade600,
                        Colors.deepPurple.shade900,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bar_chart_rounded,
                              color: Colors.white70, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Firebase Analytics',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'View episode views, active users, top dramas, engagement time and more — all live in Firebase Console.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _quickStat('episode_watched', 'Episodes'),
                          const SizedBox(width: 8),
                          _quickStat('drama_opened', 'Drama Opens'),
                          const SizedBox(width: 8),
                          _quickStat('screen_view', 'Screen Views'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openAnalytics,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Open Firebase Analytics'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Version Status ──────────────────────────────────
                if (controller.versionStatus.value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.deepPurple, size: 18),
                        const SizedBox(width: 8),
                        Text(controller.versionStatus.value,
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // ─── Recent Admin Actions ────────────────────────────
                const _SectionTitle(
                  title: 'Recent Actions',
                  icon: Icons.history_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                ...logService.logs.reversed.take(5).map((log) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(log.action,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 20),

                // ─── Recent Commits ──────────────────────────────────
                const _SectionTitle(
                  title: 'Recent Commits',
                  icon: Icons.commit_rounded,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                ...controller.recentCommits.take(5).map((commit) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.commit,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commit['message'] ?? '',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  commit['author'] ?? '',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStat(String event, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              event,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
