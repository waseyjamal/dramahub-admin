import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/config_controller.dart';
import '../../controllers/drama_controller.dart';

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

              // ✅ Build otherEntries INSIDE Obx so it reacts to config changes
              final allEntries = controller.config.entries.toList();
              final otherEntries = allEntries
                  .where((e) => e.key != 'hero_slider_dramas')
                  .toList();

              return ListView(
                children: [
                  // Hero Slider Picker always at top
                  _HeroSliderPicker(controller: controller),

                  // All other config entries
                  if (otherEntries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No other config entries.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...otherEntries.map((entry) => Card(
                          child: ListTile(
                            title: Text(entry.key),
                            subtitle: Text(entry.value.toString()),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(
                                  context, controller, entry.key, entry.value),
                            ),
                          ),
                        )),
                ],
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

class _HeroSliderPicker extends StatelessWidget {
  final ConfigController controller;

  const _HeroSliderPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dramaController = Get.find<DramaController>();
      final dramas = dramaController.dramas;

      List<String> currentIds = [];
      final raw = controller.config['hero_slider_dramas'];
      if (raw != null && raw is List) {
        currentIds = List<String>.from(
          raw.where((e) => e != null).map((e) => e.toString()),
        );
      }
      while (currentIds.length < 5) {
        currentIds.add('');
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.view_carousel_rounded,
                      color: Colors.deepPurple, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Hero Slider Control',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.deepPurple),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pick up to 5 dramas for the hero banner. Empty slots are skipped.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              ...List.generate(5, (slotIndex) {
                final slotValue =
                    slotIndex < currentIds.length ? currentIds[slotIndex] : '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: slotValue.isNotEmpty
                              ? Colors.deepPurple
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${slotIndex + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: slotValue.isNotEmpty
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: dramas.isEmpty
                            ? Text('No dramas loaded',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 13))
                            : DropdownButtonFormField<String>(
                                value: slotValue.isEmpty ? null : slotValue,
                                hint: Text(
                                  'Slot ${slotIndex + 1} — Empty',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13),
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  isDense: true,
                                ),
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem<String>(
                                    value: '',
                                    child: Text('— Empty slot —',
                                        style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 13)),
                                  ),
                                  ...dramas
                                      .map((drama) => DropdownMenuItem<String>(
                                            value: drama['id'],
                                            child: Text(
                                              drama['title'],
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                          )),
                                ],
                                onChanged: (value) async {
                                  final updatedIds =
                                      List<String>.from(currentIds);
                                  updatedIds[slotIndex] = value ?? '';

                                  final trimmed = updatedIds.reversed
                                      .skipWhile((id) => id.isEmpty)
                                      .toList()
                                      .reversed
                                      .toList();

                                  await controller.updateField(
                                      'hero_slider_dramas', trimmed);
                                },
                              ),
                      ),
                    ],
                  ),
                );
              }),
              if (currentIds.any((id) => id.isNotEmpty)) ...[
                const Divider(height: 20),
                Text(
                  'Current Slider Order:',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...currentIds
                    .asMap()
                    .entries
                    .where((e) => e.value.isNotEmpty)
                    .map((e) {
                  final drama =
                      dramas.firstWhereOrNull((d) => d['id'] == e.value);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.drag_indicator_rounded,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${e.key + 1}. ${drama?['title'] ?? e.value}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await controller.updateField('hero_slider_dramas', []);
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Reset to Default Order',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
