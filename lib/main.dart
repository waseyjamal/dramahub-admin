import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/app.dart';
import 'app/bindings.dart';

void main() {
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(),
      home: const App(),
    ),
  );
}
