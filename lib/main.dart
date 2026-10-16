import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 상단 상태바 및 하단 내비게이션 바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E222B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: BadmintonNamecardFinderApp(),
    ),
  );
}

class BadmintonNamecardFinderApp extends StatelessWidget {
  const BadmintonNamecardFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '배드민턴 명찰 찾기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121418),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00FF88),
          surface: Color(0xFF1E222B),
          error: Colors.redAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E222B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
