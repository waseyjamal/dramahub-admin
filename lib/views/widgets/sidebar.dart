import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onSelect;

  const Sidebar({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.black,
      child: Column(
        children: [
          const SizedBox(height: 40),
          _item('Dashboard', 0),
          _item('Dramas', 1),
          _item('Episodes', 2),
          _item('Config', 3),
        ],
      ),
    );
  }

  Widget _item(String title, int index) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => onSelect(index),
    );
  }
}
