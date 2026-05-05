import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/episode_controller.dart';

class EpisodeFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final int? index;

  const EpisodeFormDialog({super.key, this.existing, this.index});

  @override
  State<EpisodeFormDialog> createState() => _EpisodeFormDialogState();
}

class _EpisodeFormDialogState extends State<EpisodeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool isScheduled = false;
  DateTime? scheduledDate;

  // Player type — 'youtube' or 'custom'
  String playerType = 'youtube';

  late TextEditingController episodeNumber;
  late TextEditingController title;
  late TextEditingController videoId;
  late TextEditingController streamUrl;
  late TextEditingController thumbnailImage;
  late TextEditingController downloadUrl;
  late TextEditingController durationMinutes;
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    // Restore scheduled state
    if (existing != null && existing['releaseDate'] != null) {
      final date = DateTime.parse(existing['releaseDate']);
      if (date.isAfter(DateTime.now())) {
        isScheduled = true;
        scheduledDate = date;
      }
    }

    // Restore player type — default to 'youtube' if missing
    playerType = existing?['playerType'] ?? 'youtube';

    episodeNumber = TextEditingController(
        text: existing?['episodeNumber']?.toString() ?? '');
    title = TextEditingController(text: existing?['title'] ?? '');
    videoId = TextEditingController(text: existing?['videoId'] ?? '');
    streamUrl = TextEditingController(text: existing?['streamUrl'] ?? '');
    thumbnailImage =
        TextEditingController(text: existing?['thumbnailImage'] ?? '');
    downloadUrl = TextEditingController(text: existing?['downloadUrl'] ?? '');
    durationMinutes = TextEditingController(
        text: existing?['durationMinutes']?.toString() ?? '');
    isPremium = existing?['isPremium'] ?? false;
  }

  @override
  void dispose() {
    episodeNumber.dispose();
    title.dispose();
    videoId.dispose();
    streamUrl.dispose();
    thumbnailImage.dispose();
    downloadUrl.dispose();
    durationMinutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EpisodeController>();
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Episode' : 'Add Episode',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Episode Number
                _field(
                  episodeNumber,
                  'Episode Number',
                  true,
                  enabled: !isEdit,
                  keyboardType: TextInputType.number,
                ),

                // Title
                _field(title, 'Title', true),

                // ── Player Type Toggle ──────────────────────────────────────
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Player Type',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _playerTypeButton(
                        label: '▶  YouTube',
                        value: 'youtube',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _playerTypeButton(
                        label: '🎬  Custom HLS',
                        value: 'custom',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── YouTube ID (shown when playerType == youtube) ──────────
                if (playerType == 'youtube')
                  _field(
                    videoId,
                    'YouTube Video ID (11 chars only)',
                    true,
                  ),

                // ── Stream URL (shown when playerType == custom) ───────────
                if (playerType == 'custom')
                  _field(
                    streamUrl,
                    'Stream URL (.m3u8 from cdn.dramahubs.stream)',
                    true,
                    hint:
                        'https://cdn.dramahubs.stream/videos/slug/ep-1/index.m3u8',
                  ),

                // Thumbnail
                _field(thumbnailImage, 'Thumbnail Image URL', false),

                // Download URL
                _field(downloadUrl, 'Download URL', false),

                // Duration
                _field(
                  durationMinutes,
                  'Duration (minutes)',
                  false,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 8),

                // Premium toggle
                Row(
                  children: [
                    const Text('Premium Episode'),
                    const Spacer(),
                    Switch(
                      value: isPremium,
                      onChanged: (val) => setState(() => isPremium = val),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Release type
                Row(
                  children: [
                    const Text('Release Type'),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('Live Now'),
                      selected: !isScheduled,
                      onSelected: (_) => setState(() {
                        isScheduled = false;
                        scheduledDate = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Schedule'),
                      selected: isScheduled,
                      onSelected: (_) async {
                        final picked = await showDateTimePicker(context);
                        if (picked != null) {
                          setState(() {
                            isScheduled = true;
                            scheduledDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),

                if (isScheduled && scheduledDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepPurple.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule,
                              color: Colors.deepPurple, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Releases: ${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year} '
                            '${scheduledDate!.hour}:${scheduledDate!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: Colors.deepPurple, fontSize: 13),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDateTimePicker(context);
                              if (picked != null) {
                                setState(() => scheduledDate = picked);
                              }
                            },
                            child: const Icon(Icons.edit,
                                size: 14, color: Colors.deepPurple),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final epNum = int.tryParse(episodeNumber.text) ?? 0;
            final isCustom = playerType == 'custom';

            final data = {
              'id': widget.existing?['id'] ??
                  '${controller.currentDramaId}_ep_$epNum',
              'episodeNumber': epNum,
              'title': title.text.trim(),
              // Always save both fields — app reads playerType to decide which to use
              'playerType': playerType,
              'videoId': isCustom ? '' : videoId.text.trim(),
              'streamUrl': isCustom ? streamUrl.text.trim() : '',
              'thumbnailImage': thumbnailImage.text.trim(),
              'downloadUrl': downloadUrl.text.trim(),
              'durationMinutes': int.tryParse(durationMinutes.text) ?? 0,
              'isPremium': isPremium,
              'releaseDate': isScheduled && scheduledDate != null
                  ? scheduledDate!.toIso8601String()
                  : DateTime.now().toIso8601String(),
              'dramaId': controller.currentDramaId ?? '',
            };

            if (isEdit) {
              await controller.updateEpisode(widget.index ?? 0, data);
            } else {
              await controller.addEpisode(data);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  // Player type toggle button
  Widget _playerTypeButton({
    required String label,
    required String value,
  }) {
    final isSelected = playerType == value;
    return GestureDetector(
      onTap: () => setState(() => playerType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    bool required, {
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey.shade100,
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;
    if (!context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        scheduledDate ?? DateTime.now(),
      ),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
