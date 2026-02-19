import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/drama_controller.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/forms/drama_form_dialog.dart';

class DramaManagerPage extends StatelessWidget {
  const DramaManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DramaController>();
    final searchQuery = ''.obs;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Drama Manager',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const DramaFormDialog(),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Drama'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search dramas...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) => searchQuery.value = value.toLowerCase(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = controller.dramas
                  .where((d) =>
                      d['title'].toLowerCase().contains(searchQuery.value))
                  .toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No dramas found'));
              }

              return ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  controller.reorder(oldIndex, newIndex);
                },
                children: List.generate(filtered.length, (index) {
                  final drama = filtered[index];
                  final isActive = drama['isActive'] ?? true;

                  return Card(
                    key: ValueKey(drama['id']),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.green : Colors.grey,
                        child: Text(
                          drama['title'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        drama['title'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'ID: ${drama['id']}  •  Episodes: ${drama['totalEpisodes'] ?? 0}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue, size: 20),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => DramaFormDialog(
                                existing: drama,
                                index: index,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: Colors.orange,
                            ),
                            onPressed: () => controller.toggleActive(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            onPressed: () async {
                              final confirm = await showConfirmDialog(
                                context,
                                'Delete Drama',
                                'Delete ${drama['title']}? This cannot be undone.',
                              );
                              if (confirm) {
                                controller.deleteDrama(index);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }
}
