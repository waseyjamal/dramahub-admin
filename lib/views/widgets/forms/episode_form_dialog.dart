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
                    keyboardType: TextInputType.number),
                _field(title, 'Title (e.g. Episode 61)', true),
                _field(videoId, 'YouTube Video ID', true),
                _field(thumbnailImage, 'Thumbnail Image URL', false),
                _field(downloadUrl, 'Download URL', false),
                _field(durationMinutes, 'Duration (minutes)', false,
                    keyboardType: TextInputType.number),
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
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final data = {
              'episodeNumber': int.tryParse(episodeNumber.text) ?? 0,
              'title': title.text.trim(),
              'videoId': videoId.text.trim(),
              'thumbnailImage': thumbnailImage.text.trim(),
              'downloadUrl': downloadUrl.text.trim(),
              'durationMinutes': int.tryParse(durationMinutes.text) ?? 0,
              'isPremium': isPremium,
              'releaseDate': DateTime.now().toIso8601String(),
              'dramaId': controller.currentDramaId ?? '',
            };

            if (isEdit && widget.index != null) {
              await controller.updateEpisode(widget.index!, data);
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label is required' : null
            : null,
      ),
    );
  }
}
