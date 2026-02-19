import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/config_controller.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConfigController>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('App Config', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                children: controller.config.entries.map((entry) {
                  return Card(
                    child: ListTile(
                      title: Text(entry.key),
                      subtitle: Text(entry.value.toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(
                            context, controller, entry.key, entry.value),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    ConfigController controller,
    String key,
    dynamic currentValue,
  ) {
    final textController = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit $key'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(labelText: key),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.updateField(key, textController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
