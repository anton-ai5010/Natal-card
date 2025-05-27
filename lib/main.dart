// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Импорт flutter_dotenv
import 'screens/astro_form_screen.dart';

void main() async { // main() теперь асинхронный
  WidgetsFlutterBinding.ensureInitialized(); // Убеждаемся, что Flutter готов
await dotenv.load(fileName: "config.env"); // <-- Должно быть ТОЧНО "config.env"

  runApp(const AstroApp());
}

class AstroApp extends StatelessWidget {
  const AstroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AstroFormScreen(),
    );
  }
}