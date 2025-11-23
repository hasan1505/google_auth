import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../login/controllers/login_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: loginController.signOut,
          ),
        ],
      ),
      body: Center(
        child: Text(
          "Welcome, ${loginController.user?.displayName ?? 'User'}",
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
