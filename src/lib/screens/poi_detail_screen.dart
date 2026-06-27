import 'package:flutter/material.dart';
import '../models/poi.dart';
import '../services/app_strings.dart';
import '../services/language_controller.dart';
import '../services/tts_service.dart';

/// Schermata di dettaglio: mostra titolo e testo completo di un POI
/// nella lingua attualmente selezionata, con pulsante per ascoltarlo
/// tramite sintesi vocale (text-to-speech).
class PoiDetailScreen extends StatefulWidget {
  final Poi poi;
  final LanguageController languageController;
  final TtsService ttsService;

  const PoiDetailScreen({
    super.key,
    required this.poi,
    required this.languageController,
    required this.ttsService,
  });

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  @override
  void dispose() {
    // Se l'utente esce dalla schermata mentre il testo sta venendo letto,
    // interrompiamo la lettura: non avrebbe senso continuare a sentire la
    // voce mentre si guarda tutt'altro.
    widget.ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo sia il cambio lingua sia lo stato del TTS (per
    // aggiornare l'icona del pulsante tra "play" e "stop").
    return AnimatedBuilder(
      animation: Listenable.merge([widget.languageController, widget.ttsService]),
      builder: (context, _) {
        final lang = widget.languageController.currentLanguage;
        final localized = widget.poi.contentFor(lang);
        final isSpeaking = widget.ttsService.isSpeaking;
        final strings = AppStrings.of(lang);

        return Scaffold(
          appBar: AppBar(title: Text(localized.title)),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localized.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localized.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (isSpeaking) {
                        widget.ttsService.stop();
                      } else {
                        widget.ttsService
                            .speak(localized.text, languageCode: lang)
                            .then((_) {
                          final error = widget.ttsService.lastError;
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        });
                      }
                    },
                    icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
                    label: Text(isSpeaking ? strings.stopListening : strings.listen),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
