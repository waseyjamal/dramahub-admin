import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/drama_controller.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/forms/drama_form_dialog.dart';

class DramaManagerPage extends StatefulWidget {
  const DramaManagerPage({super.key});

  @override
  State<DramaManagerPage> createState() => _DramaManagerPageState();
}

class _DramaManagerPageState extends State<DramaManagerPage> {
  late final DramaController controller;
  final searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DramaController>();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Drama Manager',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const DramaFormDialog(),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Drama'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search dramas...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => searchQuery.value = v.toLowerCase(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = controller.dramas
                    .where((d) => d['title']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.value))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No dramas found'));
                }

                final isSearching = searchQuery.value.isNotEmpty;

                return ReorderableListView.builder(
                  restorationId: 'drama_reorder_list',
                  onReorder: isSearching
                      ? (oldIndex, newIndex) {}
                      : (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          controller.reorder(oldIndex, newIndex);
                        },
                  buildDefaultDragHandles: false,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final drama = filtered[index];
                    final isActive = drama['isActive'] ?? true;

                    return Container(
                      key: ValueKey(drama['id'] ?? index.toString()),
                      margin: const EdgeInsets.only(bottom: 10),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (!isSearching)
                                  ReorderableDelayedDragStartListener(
                                    index: index,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(
                                          Icons.drag_handle_rounded,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isActive
                                      ? Colors.deepPurple
                                      : Colors.grey,
                                  child: Text(
                                    drama['title'][0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    drama['title'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ID: ${drama['id']}  •  Episodes: ${drama['totalEpisodes'] ?? 0}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _actionBtn(
                                  icon: Icons.edit,
                                  color: Colors.blue,
                                  label: 'Edit',
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => DramaFormDialog(
                                      existing: drama,
                                      index: index,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _actionBtn(
                                  icon: isActive
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.orange,
                                  label: isActive ? 'Hide' : 'Show',
                                  onTap: () => controller.toggleActive(index),
                                ),
                                const SizedBox(width: 8),
                                _actionBtn(
                                  icon: Icons.delete,
                                  color: Colors.red,
                                  label: 'Delete',
                                  onTap: () async {
                                    final confirm = await showConfirmDialog(
                                      context,
                                      'Delete Drama',
                                      'Delete ${drama['title']}? Cannot be undone.',
                                    );
                                    if (confirm) {
                                      controller.deleteDrama(index);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
