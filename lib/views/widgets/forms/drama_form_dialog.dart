import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/drama_controller.dart';

class DramaFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const DramaFormDialog({super.key, this.existing});

  @override
  State<DramaFormDialog> createState() => _DramaFormDialogState();
}

class _DramaFormDialogState extends State<DramaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController title;
  late TextEditingController id;
  late TextEditingController description;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.existing?['title'] ?? '');
    id = TextEditingController(text: widget.existing?['id'] ?? '');
    description =
        TextEditingController(text: widget.existing?['description'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DramaController>();

    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Drama' : 'Edit Drama'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: id,
                decoration: const InputDecoration(labelText: 'ID'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
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
              'id': id.text,
              'title': title.text,
              'description': description.text,
              'posterImage': '',
              'bannerImage': '',
              'totalEpisodes': 0,
              'genre': '',
              'rating': 0,
              'releaseYear': 2024,
              'isActive': true,
              'order': 0,
            };

            if (widget.existing == null) {
              await controller.addDrama(data);
            }

            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
