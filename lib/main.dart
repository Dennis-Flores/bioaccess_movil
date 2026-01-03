// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'core/config.dart';
import 'features/auth/presentation/user_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BioAccessApp()));
}

class BioAccessApp extends StatelessWidget {
  const BioAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildBioAccessTheme(),
      home: const UserLoginScreen(),
    );
  }
}
