import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/drama_controller.dart';

class DramaFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final int? index;

  const DramaFormDialog({super.key, this.existing, this.index});

  @override
  State<DramaFormDialog> createState() => _DramaFormDialogState();
}

class _DramaFormDialogState extends State<DramaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController id;
  late TextEditingController title;
  late TextEditingController description;
  late TextEditingController posterImage;
  late TextEditingController bannerImage;
  late TextEditingController genre;
  late TextEditingController rating;
  late TextEditingController releaseYear;
  late TextEditingController premiereDate;
  late bool isComingSoon;

  @override
  void initState() {
    super.initState();
    id = TextEditingController(text: widget.existing?['id'] ?? '');
    title = TextEditingController(text: widget.existing?['title'] ?? '');
    description =
        TextEditingController(text: widget.existing?['description'] ?? '');
    posterImage =
        TextEditingController(text: widget.existing?['posterImage'] ?? '');
    bannerImage =
        TextEditingController(text: widget.existing?['bannerImage'] ?? '');
    genre = TextEditingController(text: widget.existing?['genre'] ?? '');
    rating = TextEditingController(
        text: widget.existing?['rating']?.toString() ?? '0');
    releaseYear = TextEditingController(
        text: widget.existing?['releaseYear']?.toString() ?? '2024');
    premiereDate = TextEditingController(
        text: widget.existing?['premiereDate'] ?? '');
    isComingSoon = widget.existing?['isComingSoon'] ?? false;
  }

  @override
  void dispose() {
    id.dispose();
    title.dispose();
    description.dispose();
    posterImage.dispose();
    bannerImage.dispose();
    genre.dispose();
    rating.dispose();
    releaseYear.dispose();
    premiereDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DramaController>();
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Drama' : 'Add Drama',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(id, 'ID (e.g. AraftaHindi)', isEdit ? false : true),
                _field(title, 'Title', true),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: description,
                    maxLines: 6,
                    minLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                _field(posterImage, 'Poster Image URL', false),
                _field(bannerImage, 'Banner Image URL', false),
                _field(genre, 'Genre', false),
                _field(rating, 'Rating (0-10)', false),
                _field(releaseYear, 'Release Year', false),

                // Coming Soon toggle
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: StatefulBuilder(
                      builder: (context, setInner) => SwitchListTile(
                        title: const Text('Coming Soon'),
                        subtitle: const Text(
                          'Drama appears in Coming Soon section only — hidden from All Dramas',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: isComingSoon,
                        activeColor: Colors.redAccent,
                        onChanged: (val) {
                          setInner(() => isComingSoon = val);
                          setState(() => isComingSoon = val);
                        },
                      ),
                    ),
                  ),
                ),

                // Premiere Date — only shown when Coming Soon is ON
                if (isComingSoon)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: premiereDate,
                      decoration: const InputDecoration(
                        labelText: 'Premiere Date (YYYY-MM-DD)',
                        hintText: 'e.g. 2026-07-15',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate == null) return;
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime == null) return;
                        final full = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        premiereDate.text = full.toIso8601String();
                      },
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
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final data = {
              'id': id.text.trim(),
              'title': title.text.trim(),
              'description': description.text.trim(),
              'posterImage': posterImage.text.trim(),
              'bannerImage': bannerImage.text.trim(),
              'genre': genre.text.trim(),
              'rating': double.tryParse(rating.text) ?? 0,
              'releaseYear': int.tryParse(releaseYear.text) ?? 2024,
              'totalEpisodes': widget.existing?['totalEpisodes'] ?? 0,
              'isActive': widget.existing?['isActive'] ?? true,
              'order': widget.existing?['order'] ?? 0,
              'isComingSoon': isComingSoon,
              'premiereDate': isComingSoon ? premiereDate.text.trim() : null,
              'addedOn': isEdit
                  ? (widget.existing?['addedOn'] ?? DateTime.now().toUtc().toIso8601String())
                  : DateTime.now().toUtc().toIso8601String(),
            };

            if (isEdit && widget.index != null) {
              await controller.updateDrama(widget.index!, data);
            } else {
              await controller.addDrama(data);
            }

            if (context.mounted) Navigator.pop(context);
          },
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
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