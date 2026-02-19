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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Obx(() {
              final episodes = controller.episodes;

              final totalPages = (episodes.length / pageSize).ceil();

              final visible = episodes
                  .skip(currentPage.value * pageSize)
                  .take(pageSize)
                  .toList();

              return CustomScrollView(
                slivers: [
                  // ================= HEADER =================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Episode Manager',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          controller.currentDramaId != null
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
                              : const SizedBox(),
                        ],
                      ),
                    ),
                  ),

                  // ================= DROPDOWN =================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
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
                                    child: Text(
                                      d['title'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              currentPage.value = 0;
                              controller.loadEpisodes(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),

                  // ================= EMPTY STATES =================
                  if (controller.isLoading.value)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (controller.currentDramaId == null)
                    _emptySliver(
                        icon: Icons.video_library_outlined,
                        text: 'Select a drama to view episodes')
                  else if (episodes.isEmpty)
                    _emptySliver(
                        icon: Icons.movie_outlined, text: 'No episodes yet')
                  else ...[
                    // ================= EPISODE LIST =================
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final episode = visible[index];
                          final realIndex =
                              currentPage.value * pageSize + index;
                          final isPremium = episode['isPremium'] == true;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: _episodeTile(
                              context,
                              episode,
                              realIndex,
                              isPremium,
                            ),
                          );
                        },
                        childCount: visible.length,
                      ),
                    ),

                    // ================= PAGINATION =================
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: currentPage.value > 0
                                  ? () => currentPage.value--
                                  : null,
                              icon: const Icon(Icons.arrow_back_ios, size: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Page ${currentPage.value + 1} of $totalPages',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: currentPage.value < totalPages - 1
                                  ? () => currentPage.value++
                                  : null,
                              icon:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ================= EPISODE TILE =================

  Widget _episodeTile(
    BuildContext context,
    Map<String, dynamic> episode,
    int realIndex,
    bool isPremium,
  ) {
    return Container(
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            '${episode['episodeNumber']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          episode['title'] ?? 'Episode ${episode['episodeNumber']}',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Video: ${episode['videoId'] ?? '-'}',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPremium)
              const Icon(Icons.star, color: Colors.orange, size: 18),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => EpisodeFormDialog(
                  existing: episode,
                  index: realIndex,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              onPressed: () async {
                final confirm = await showConfirmDialog(
                  context,
                  'Delete Episode',
                  'Delete Episode ${episode['episodeNumber']}?',
                );
                if (confirm) {
                  Get.find<EpisodeController>().deleteEpisode(realIndex);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= EMPTY SLIVER =================

  SliverFillRemaining _emptySliver({
    required IconData icon,
    required String text,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              text,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
