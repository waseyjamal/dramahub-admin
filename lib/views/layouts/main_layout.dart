import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/dashboard_page.dart';
import '../pages/drama_manager_page.dart';
import '../pages/episode_manager_page.dart';
import '../pages/config_page.dart';
import '../../controllers/auth_controller.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = 0.obs;

    final pages = [
      const DashboardPage(),
      const DramaManagerPage(),
      const EpisodeManagerPage(),
      const ConfigPage(),
    ];

    return Obx(() => Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A2E),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'DramaHub Admin',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                onPressed: () => Get.find<AuthController>().logout(),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: pages[selectedIndex.value],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex.value,
            onTap: (index) => selectedIndex.value = index,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF1A1A2E),
            selectedItemColor: Colors.deepPurple.shade200,
            unselectedItemColor: Colors.white38,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.movie_outlined),
                activeIcon: Icon(Icons.movie),
                label: 'Dramas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                activeIcon: Icon(Icons.play_circle),
                label: 'Episodes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Config',
              ),
            ],
          ),
        ));
  }
}
