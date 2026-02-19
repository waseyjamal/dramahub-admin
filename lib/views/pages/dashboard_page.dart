import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/admin_log_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final logService = Get.find<AdminLogService>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 16),

                // Health Panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: controller.systemHealth.value == 'HEALTHY'
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.systemHealth.value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'API Latency: ${controller.apiLatency} ms',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Stats
                Text('Total Dramas: ${controller.totalDramas}'),
                Text('Total Episodes: ${controller.totalEpisodes}'),
                Text('GitHub Connected: ${controller.isConnected}'),
                Text(
                    'Rate Limit: ${controller.rateRemaining}/${controller.rateLimit}'),
                Text('Version: ${controller.versionStatus}'),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: controller.refreshStats,
                  child: const Text('Refresh'),
                ),

                const SizedBox(height: 30),

                // Recent Admin Actions
                const Text('Recent Admin Actions',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Obx(() => Column(
                      children: logService.logs.reversed
                          .take(10)
                          .map((log) => Card(
                                child: ListTile(
                                  title: Text(log.action),
                                  subtitle:
                                      Text(log.timestamp.toIso8601String()),
                                ),
                              ))
                          .toList(),
                    )),

                const SizedBox(height: 30),

                // Recent Commits
                const Text('Recent Repository Commits',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Column(
                  children: controller.recentCommits
                      .map((commit) => Card(
                            child: ListTile(
                              title: Text(commit['message']),
                              subtitle: Text(
                                  '${commit['author']} – ${commit['date']}'),
                            ),
                          ))
                      .toList(),
                ),
              ],
            )),
      ),
    );
  }
}
