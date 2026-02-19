import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/episode_controller.dart';
import '../../controllers/drama_controller.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/forms/episode_form_dialog.dart';

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
          Row(
            children: [
              const Text('Episode Manager',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              Obx(() => controller.currentDramaId != null
                  ? ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const EpisodeFormDialog(),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Episode'),
                    )
                  : const SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
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
                ),
              )),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.currentDramaId == null) {
                return const Center(child: Text('Please select a drama above'));
              }

              if (controller.episodes.isEmpty) {
                return const Center(child: Text('No episodes yet'));
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
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Text(
                                '${episode['episodeNumber']}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            title: Text(
                              episode['title'] ??
                                  'Episode ${episode['episodeNumber']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'ID: ${episode['videoId'] ?? 'No video ID'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (episode['isPremium'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Premium',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 11)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue, size: 20),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => EpisodeFormDialog(
                                      existing: episode,
                                      index: realIndex,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => currentPage.value =
                            (currentPage.value - 1).clamp(0, 999),
                        icon: const Icon(Icons.arrow_back_ios),
                      ),
                      Obx(() => Text(
                            'Page ${currentPage.value + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                      IconButton(
                        onPressed: () => currentPage.value++,
                        icon: const Icon(Icons.arrow_forward_ios),
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
