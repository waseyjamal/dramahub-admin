import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../pages/dashboard_page.dart';
import '../pages/drama_manager_page.dart';
import '../pages/episode_manager_page.dart';
import '../pages/config_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;

  final pages = [
    const DashboardPage(),
    const DramaManagerPage(),
    const EpisodeManagerPage(),
    const ConfigPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            onSelect: (index) {
              setState(() => selectedIndex = index);
            },
          ),
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}
