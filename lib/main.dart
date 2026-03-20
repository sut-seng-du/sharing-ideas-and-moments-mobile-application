import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/twitter_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  TwitterService.initDeepLinkListener(); // Listen globally so callbacks resolve authenticate()
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharing Ideas and Moments',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E608E),
          primary: const Color(0xFF0E608E),
          secondary: const Color(0xFFF8A41E),
          surface: const Color(0xFFF0F2F5),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF0F2F5),
          foregroundColor: Color(0xFF0E608E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
