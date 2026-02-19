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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Episode Manager',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Obx(() => controller.currentDramaId != null
                            ? ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => const EpisodeFormDialog(),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Episode'),
                              )
                            : const SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            underline: const SizedBox(),
                            hint: const Text('Select Drama'),
                            value: controller.currentDramaId,
                            items: dramaController.dramas
                                .map((d) => DropdownMenuItem(
                                      value: d['id'] as String,
                                      child: Text(d['title'],
                                          overflow: TextOverflow.ellipsis),
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
                    const SizedBox(height: 12),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (controller.currentDramaId == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_library_outlined,
                                    size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Select a drama to view episodes',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          );
                        }

                        if (controller.episodes.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.movie_outlined,
                                    size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text('No episodes yet'),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => const EpisodeFormDialog(),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Episode'),
                                ),
                              ],
                            ),
                          );
                        }

                        final totalPages =
                            (controller.episodes.length / pageSize).ceil();

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
                                  final realIndex =
                                      currentPage.value * pageSize + index;
                                  final isPremium =
                                      episode['isPremium'] == true;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.deepPurple,
                                            child: Text(
                                              '${episode['episodeNumber']}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  episode['title'] ??
                                                      'Episode ${episode['episodeNumber']}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'Video: ${episode['videoId'] ?? '-'}',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade500),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isPremium)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  right: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text('PRO',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue, size: 18),
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
                                                color: Colors.red, size: 18),
                                            onPressed: () async {
                                              final confirm =
                                                  await showConfirmDialog(
                                                context,
                                                'Delete Episode',
                                                'Delete Episode ${episode['episodeNumber']}?',
                                              );
                                              if (confirm) {
                                                controller
                                                    .deleteEpisode(realIndex);
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
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: currentPage.value > 0
                                        ? () => currentPage.value--
                                        : null,
                                    icon: const Icon(Icons.arrow_back_ios,
                                        size: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Page ${currentPage.value + 1} of $totalPages',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        currentPage.value < totalPages - 1
                                            ? () => currentPage.value++
                                            : null,
                                    icon: const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
