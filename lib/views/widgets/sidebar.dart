import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.movie_outlined, 'label': 'Dramas'},
      {'icon': Icons.play_circle_outline, 'label': 'Episodes'},
      {'icon': Icons.settings_outlined, 'label': 'Config'},
    ];

    return Container(
      width: 200,
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'DramaHub',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = selectedIndex == index;

            return GestureDetector(
              onTap: () => onItemTapped(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          const Divider(color: Colors.white12, height: 1),
          GestureDetector(
            onTap: () => Get.find<AuthController>().logout(),
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 18),
                  SizedBox(width: 10),
                  Text('Logout',
                      style: TextStyle(color: Colors.red, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
