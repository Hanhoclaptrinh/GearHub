import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ),
  );

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
