import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ApiService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume theme settings reactively
    final apiState = Provider.of<ApiService>(context);

    return MaterialApp(
      title: 'FinAgent Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData(isDark: apiState.isDarkTheme),
      home: const SplashScreen(),
    );
  }
}

