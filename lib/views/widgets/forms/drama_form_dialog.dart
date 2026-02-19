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
                _field(id, 'ID (e.g. arafta)', isEdit ? false : true),
                _field(title, 'Title', true),
                _field(description, 'Description', false),
                _field(posterImage, 'Poster Image URL', false),
                _field(bannerImage, 'Banner Image URL', false),
                _field(genre, 'Genre', false),
                _field(rating, 'Rating (0-10)', false),
                _field(releaseYear, 'Release Year', false),
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
            };

            if (isEdit && widget.index != null) {
              await controller.updateDrama(widget.index!, data);
            } else {
              await controller.addDrama(data);
            }

            Navigator.pop(context);
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
