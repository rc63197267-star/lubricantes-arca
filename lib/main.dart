import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/server_config.dart';

Future<void> main() async {
  await initServerConfig();
  runApp(const LubricantesArcaApp());
}

// Responsive utilities
class ResponsiveSize {
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 480) return 12;
    if (width < 768) return 14;
    if (width < 1200) return 20;
    return 28;
  }

  static double getVerticalPadding(BuildContext context) {
    return MediaQuery.of(context).size.width < 768 ? 12 : 18;
  }

  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 380;

  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 380) return 1;
    if (width < 600) return 2;
    if (width < 900) return 3;
    return 4;
  }
}

class LubricantesArcaApp extends StatelessWidget {
  const LubricantesArcaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lubricantes Arca Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A2540),
          primary: const Color(0xFF0A2540),
          secondary: const Color(0xFF5F7DB6),
          surface: const Color(0xFFF7F9FB),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
