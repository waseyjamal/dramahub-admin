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
  late TextEditingController episodeNumber;
  late TextEditingController title;
  late TextEditingController videoId;
  late TextEditingController thumbnailImage;
  late TextEditingController downloadUrl;
  late TextEditingController durationMinutes;
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null && existing['releaseDate'] != null) {
      final date = DateTime.parse(existing['releaseDate']);
      if (date.isAfter(DateTime.now())) {
        isScheduled = true;
        scheduledDate = date;
      }
    }
    episodeNumber = TextEditingController(
        text: widget.existing?['episodeNumber']?.toString() ?? '');
    title = TextEditingController(text: widget.existing?['title'] ?? '');
    videoId = TextEditingController(text: widget.existing?['videoId'] ?? '');
    thumbnailImage =
        TextEditingController(text: widget.existing?['thumbnailImage'] ?? '');
    downloadUrl =
        TextEditingController(text: widget.existing?['downloadUrl'] ?? '');
    durationMinutes = TextEditingController(
        text: widget.existing?['durationMinutes']?.toString() ?? '');
    isPremium = widget.existing?['isPremium'] ?? false;
  }

  @override
  void dispose() {
    episodeNumber.dispose();
    title.dispose();
    videoId.dispose();
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
      title: Text(isEdit ? 'Edit Episode' : 'Add Episode',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(episodeNumber, 'Episode Number', true,
                    enabled: !isEdit, keyboardType: TextInputType.number),
                _field(title, 'Title', true),
                _field(videoId, 'YouTube Video ID', true),
                _field(thumbnailImage, 'Thumbnail Image URL', false),
                _field(downloadUrl, 'Download URL', false),
                _field(durationMinutes, 'Duration (minutes)', false,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
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
                            'Releases: ${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year} ${scheduledDate!.hour}:${scheduledDate!.minute.toString().padLeft(2, '0')}',
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

            final data = {
              'id': widget.existing?['id'] ??
                  '${controller.currentDramaId}_ep_$epNum',
              'episodeNumber': epNum,
              'title': title.text.trim(),
              'videoId': videoId.text.trim(),
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

            Navigator.pop(context);
          },
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    bool required, {
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
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
