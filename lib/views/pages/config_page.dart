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
                  .where((e) => !['hero_slider_dramas', 'data_version', 'cdn_base', 'instagram_url', 'website_url'].contains(e.key))
                  .toList();

              return ListView(
                children: [
                  // Hero Slider Picker always at top
                  _HeroSliderPicker(controller: controller),

                  _DataVersionCard(controller: controller),
                  
                  _UrlConfigCard(
                    controller: controller,
                    configKey: 'instagram_url',
                    label: 'Instagram URL',
                    defaultValue: 'https://instagram.com/arafta_hindi',
                    description: 'Link to the official Instagram profile.',
                    icon: Icons.camera_alt_rounded,
                    requireHttps: true,
                  ),
                  _UrlConfigCard(
                    controller: controller,
                    configKey: 'website_url',
                    label: 'Website URL',
                    defaultValue: 'https://drama-hubs.blogspot.com',
                    description: 'Link to the official website.',
                    icon: Icons.language_rounded,
                    requireHttps: true,
                  ),
                  _UrlConfigCard(
                    controller: controller,
                    configKey: 'cdn_base',
                    label: 'CDN Base URL',
                    defaultValue: 'https://dramahub-data.waseyjamal000.workers.dev',
                    description: 'Emergency CDN switch — change only if Cloudflare is down.',
                    icon: Icons.link_rounded,
                    requireHttps: true,
                    noTrailingSlash: true,
                    hintText: 'https://dramahub-data.waseyjamal000.workers.dev',
                  ),

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
              if (context.mounted) Navigator.pop(context);
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
                                initialValue: slotValue.isEmpty ? null : slotValue,
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
                                  // ✅ deduplicate by id — prevents assertion error when
                                  // same drama appears multiple times in dramas list
                                  ...{for (var d in dramas) d['id']: d}
                                      .values
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

class _DataVersionCard extends StatelessWidget {
  final ConfigController controller;

  const _DataVersionCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentVersion =
          int.tryParse(controller.config['data_version']?.toString() ?? '1') ??
              1;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.orange, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Cache Invalidation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Bump version after uploading new episodes or dramas. All users will fetch fresh data within 15 minutes.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Current version display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Current Version',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v$currentVersion',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Arrow
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.grey.shade400,
                  ),

                  const SizedBox(width: 12),

                  // Next version display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'After Bump',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${currentVersion + 1}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bump button
                  Obx(() => ElevatedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Bump Data Version?'),
                                    content: Text(
                                      'Version will change from v$currentVersion → v${currentVersion + 1}.\n\nAll users will fetch fresh content within 15 minutes.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                        child: const Text('Bump'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await controller.updateField(
                                    'data_version',
                                    currentVersion + 1,
                                  );
                                }
                              },
                        icon: controller.isLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                        label: Text(
                          controller.isLoading.value
                              ? 'Saving...'
                              : 'Bump Version',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _UrlConfigCard extends StatefulWidget {
  final ConfigController controller;
  final String configKey;
  final String label;
  final String defaultValue;
  final String description;
  final IconData icon;
  final bool requireHttps;
  final bool noTrailingSlash;
  final String? hintText;

  const _UrlConfigCard({
    required this.controller,
    required this.configKey,
    required this.label,
    required this.defaultValue,
    required this.description,
    required this.icon,
    this.requireHttps = false,
    this.noTrailingSlash = false,
    this.hintText,
  });

  @override
  State<_UrlConfigCard> createState() => _UrlConfigCardState();
}

class _UrlConfigCardState extends State<_UrlConfigCard> {
  late TextEditingController _textController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final currentValue = widget.controller.config[widget.configKey]?.toString() ?? widget.defaultValue;
    _textController = TextEditingController(text: currentValue);
  }

  void _validateAndSave() async {
    final value = _textController.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = 'Cannot be empty');
      return;
    }
    if (widget.requireHttps && !value.startsWith('https://')) {
      setState(() => _errorText = 'Must start with https://');
      return;
    }
    if (widget.noTrailingSlash && value.endsWith('/')) {
      setState(() => _errorText = 'Must not end with a trailing slash');
      return;
    }

    setState(() => _errorText = null);
    await widget.controller.updateField(widget.configKey, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.label} saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: widget.label,
                      hintText: widget.hintText ?? widget.defaultValue,
                      errorText: _errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => ElevatedButton.icon(
                      onPressed: widget.controller.isLoading.value ? null : _validateAndSave,
                      icon: widget.controller.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(widget.controller.isLoading.value ? 'Saving...' : 'Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
