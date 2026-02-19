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
              const Text('Drama Manager', style: TextStyle(fontSize: 24)),
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
            decoration: const InputDecoration(
              hintText: 'Search dramas...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
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

              return ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  controller.reorder(oldIndex, newIndex);
                },
                children: List.generate(filtered.length, (index) {
                  final drama = filtered[index];
                  return Card(
                    key: ValueKey(drama['id']),
                    child: ListTile(
                      title: Text(drama['title']),
                      subtitle: Text(drama['id']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statusBadge(drama['isActive'] ?? true),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => DramaFormDialog(existing: drama),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showConfirmDialog(
                                context,
                                'Delete Drama',
                                'Are you sure you want to delete ${drama['title']}?',
                              );
                              if (confirm) {
                                controller.deleteDrama(index);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              drama['isActive'] == true
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => controller.toggleActive(index),
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

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
