import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/storage_service.dart';
import '../../core/constants/storage_keys.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _hasSavedToken = false;
  bool _showTokenField = false;

  @override
  void initState() {
    super.initState();
    final storage = Get.find<StorageService>();
    final raw = storage.getItem(StorageKeys.token);
    _hasSavedToken = raw != null && raw.toString().isNotEmpty;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final storage = Get.find<StorageService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SizedBox(
          width: 360,
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('DramaHub Admin',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _hasSavedToken
                        ? 'Enter your password to continue'
                        : 'Enter password and GitHub PAT',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_hasSavedToken || _showTokenField) ...[
                    TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        labelText: 'GitHub PAT',
                        prefixIcon: const Icon(Icons.key_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_hasSavedToken && !_showTokenField)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _showTokenField = true),
                        child: const Text('Use different PAT?',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final password = _passwordController.text;

                        String token;
                        if (_hasSavedToken && !_showTokenField) {
                          token = await storage.getToken(password) ?? '';
                        } else {
                          token = _tokenController.text.trim();
                        }

                        if (token.isEmpty) {
                          Get.find<AuthController>().errorMessage.value =
                              'Could not retrieve PAT. Enter it manually.';
                          setState(() => _showTokenField = true);
                          return;
                        }

                        await controller.login(password, token);
                      },
                      child:
                          const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => controller.errorMessage.value.isNotEmpty
                      ? Text(
                          controller.errorMessage.value,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        )
                      : const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
