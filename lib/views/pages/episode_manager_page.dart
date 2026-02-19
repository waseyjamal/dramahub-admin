import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/episode_controller.dart';
import '../../controllers/drama_controller.dart';
import '../widgets/dialogs/confirm_dialog.dart';

class EpisodeManagerPage extends StatelessWidget {
  const EpisodeManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EpisodeController>();
    final dramaController = Get.find<DramaController>();
    final currentPage = 0.obs;
    const pageSize = 20;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Episode Manager', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Obx(() => DropdownButton<String>(
                hint: const Text('Select Drama'),
                value: controller.currentDramaId,
                items: dramaController.dramas
                    .map((d) => DropdownMenuItem(
                          value: d['id'] as String,
                          child: Text(d['title']),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    currentPage.value = 0;
                    controller.loadEpisodes(value);
                  }
                },
              )),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final visible = controller.episodes
                  .skip(currentPage.value * pageSize)
                  .take(pageSize)
                  .toList();

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final episode = visible[index];
                        final realIndex = currentPage.value * pageSize + index;
                        return Card(
                          child: ListTile(
                            title: Text('Episode ${episode['episodeNumber']}'),
                            subtitle: Text(episode['title'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (episode['isPremium'] == true)
                                  const Chip(
                                    label: Text('Premium'),
                                    backgroundColor: Colors.orange,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showConfirmDialog(
                                      context,
                                      'Delete Episode',
                                      'Delete Episode ${episode['episodeNumber']}?',
                                    );
                                    if (confirm) {
                                      controller.deleteEpisode(realIndex);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => currentPage.value =
                            (currentPage.value - 1).clamp(0, 999),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Obx(() => Text('Page ${currentPage.value + 1}')),
                      IconButton(
                        onPressed: () => currentPage.value++,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
