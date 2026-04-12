import 'package:flutter/material.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/splash/presentation/pages/splash_page.dart';

void main() {
  runApp(const GearHubApp());
}

class GearHubApp extends StatelessWidget {
  const GearHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GearHub',
      theme: AppTheme.theme(context, isDark: false),
      darkTheme: AppTheme.theme(context, isDark: true),
      themeMode: ThemeMode.system,
      home: const SplashPage(),
    );
  }
}
