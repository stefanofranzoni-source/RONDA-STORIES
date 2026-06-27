import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/circuit.dart';
import '../services/app_strings.dart';
import '../services/language_controller.dart';
import '../services/tts_service.dart';

/// Schermata Impostazioni: parametri configurabili dell'app.
class SettingsScreen extends StatelessWidget {
  final LanguageController languageController;
  final TtsService ttsService;
  final Circuit? circuit;

  const SettingsScreen({
    super.key,
    required this.languageController,
    required this.ttsService,
    this.circuit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageController, ttsService]),
      builder: (context, _) {
        final lang = languageController.currentLanguage;
        final strings = AppStrings.of(lang);

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
            title: Text(strings.settings),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Sezione: Lingua
              _SettingsSection(
                title: strings.language,
                children: [
                  _LanguageTile(languageController: languageController),
                ],
              ),

              const SizedBox(height: 20),

              // Sezione: Percorso
              _SettingsSection(
                title: strings.routeSettings,
                children: [
                  _SwitchTile(
                    title: strings.poiRetrigger,
                    subtitle: strings.poiRetriggerDesc,
                    value: true, // TODO: collegare a SharedPreferences
                    onChanged: (v) {},
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sezione: Voce
              _SettingsSection(
                title: strings.voiceSettings,
                children: [
                  _SliderTile(
                    title: strings.voiceSpeed,
                    value: ttsService.speechRate,
                    min: 0.25,
                    max: 0.9,
                    // Etichette ai due estremi per chiarire il significato
                    minLabel: '🐢',
                    maxLabel: '🐇',
                    onChanged: (v) => ttsService.setSpeechRate(v),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Pulsante Esci
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(strings.exitApp),
                      content: Text(strings.exitAppConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(strings.cancel),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          onPressed: () => SystemNavigator.pop(),
                          child: Text(strings.exitApp),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.exit_to_app),
                label: Text(strings.exitApp),
              ),

              const SizedBox(height: 8),

              // Versione app e circuito
              Center(
                child: Column(
                  children: [
                    Text(
                      'Ronda Stories v0.1.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    if (circuit != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${circuit!.name} v${circuit!.version}  •  ${circuit!.versionDate}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '© ${circuit!.author}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Widget di supporto per i Settings
// ---------------------------------------------------------------------------

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final LanguageController languageController;
  static const _languages = {
    'it': 'Italiano',
    'en': 'English',
    'zh': '中文',
  };

  const _LanguageTile({required this.languageController});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Lingua / Language'),
      trailing: DropdownButton<String>(
        value: languageController.currentLanguage,
        underline: const SizedBox.shrink(),
        items: _languages.entries.map((e) => DropdownMenuItem(
          value: e.key,
          child: Text(e.value),
        )).toList(),
        onChanged: (v) { if (v != null) languageController.setLanguage(v); },
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final String? minLabel;
  final String? maxLabel;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.minLabel,
    this.maxLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Row(
            children: [
              if (minLabel != null)
                Text(minLabel!, style: const TextStyle(fontSize: 18)),
              Expanded(
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: 13,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: onChanged,
                ),
              ),
              if (maxLabel != null)
                Text(maxLabel!, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}
