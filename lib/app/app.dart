import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../views/pages/login_page.dart';
import '../views/layouts/main_layout.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      if (!authController.isAuthenticated.value) {
        return const LoginPage();
      }
      return const MainLayout();
    });
  }
}
