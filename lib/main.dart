import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const MedicineReminderApp());
}

class MedicineReminderApp extends StatelessWidget {
  const MedicineReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF18312F);
    final textTheme = ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        );

    return MaterialApp(
      title: 'Medminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E54),
          surface: const Color(0xFFFFFFFF),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        textTheme: textTheme.copyWith(
          bodySmall: textTheme.bodySmall?.copyWith(fontSize: 16),
          bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 18),
          bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 20),
          labelLarge: textTheme.labelLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          titleSmall: textTheme.titleSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F6),
          foregroundColor: ink,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          labelStyle: TextStyle(fontSize: 18),
          hintStyle: TextStyle(fontSize: 18),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 56),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 56),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 52),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
