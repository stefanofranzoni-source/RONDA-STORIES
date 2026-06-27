import 'package:flutter/material.dart';
import '../models/circuit.dart';
import '../services/app_strings.dart';
import '../services/language_controller.dart';
import '../services/tts_service.dart';
import 'poi_detail_screen.dart';

/// Schermata con la lista completa dei POI del circuito.
/// Accessibile dal pulsante "Esplora" nella Home — per chi vuole
/// leggere i contenuti prima di partire o senza GPS attivo.
class PoiListScreen extends StatelessWidget {
  final Circuit circuit;
  final LanguageController languageController;
  final TtsService ttsService;

  const PoiListScreen({
    super.key,
    required this.circuit,
    required this.languageController,
    required this.ttsService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        final lang = languageController.currentLanguage;
        final strings = AppStrings.of(lang);
        final themeColor = Color(circuit.themeColorValue);

        return Scaffold(
          appBar: AppBar(
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset('assets/images/logo_ronda.png'),
                  ),
            title: Text(circuit.name),
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Sottotitolo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: themeColor.withOpacity(0.08),
                child: Text(
                  circuit.subtitleFor(lang),
                  style: TextStyle(
                    fontSize: 14,
                    color: themeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Lista POI
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: circuit.poi.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final poi = circuit.poi[index];
                    final localized = poi.contentFor(lang);

                    return Material(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PoiDetailScreen(
                              poi: poi,
                              languageController: languageController,
                              ttsService: ttsService,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Numero ordine
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: themeColor.withOpacity(0.12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${poi.order}',
                                    style: TextStyle(
                                      color: themeColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localized.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      localized.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
