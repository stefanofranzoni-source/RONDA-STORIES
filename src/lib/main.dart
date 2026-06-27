import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/tts_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Orienta l'app solo in verticale (portrait)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const RondaApp());
}

class RondaApp extends StatefulWidget {
  const RondaApp({super.key});

  @override
  State<RondaApp> createState() => _RondaAppState();
}

class _RondaAppState extends State<RondaApp> {
  final TtsService _ttsService = TtsService();

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ronda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB7472A),
        useMaterial3: true,
        // Tipografia leggermente più spaziata per leggibilità outdoor
        textTheme: const TextTheme(
          bodyLarge: TextStyle(height: 1.5),
          bodyMedium: TextStyle(height: 1.5),
        ),
      ),
      home: HomeScreen(ttsService: _ttsService),
    );
  }
}
