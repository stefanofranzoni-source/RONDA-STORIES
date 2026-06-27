import 'package:flutter/material.dart';
import '../models/circuit.dart';
import '../models/circuit_summary.dart';
import '../services/app_strings.dart';
import '../services/circuit_loader.dart';
import '../services/language_controller.dart';
import '../services/tts_service.dart';
import 'map_screen.dart';
import 'poi_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final TtsService ttsService;
  const HomeScreen({super.key, required this.ttsService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CircuitSummary>? _catalog;
  String? _errorMessage;
  late final LanguageController _languageController;

  @override
  void initState() {
    super.initState();
    _languageController = LanguageController('it');
    _loadCatalog();
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await CircuitLoader.loadCatalog();
      setState(() => _catalog = catalog);
    } catch (e) {
      setState(() => _errorMessage = 'Errore nel caricamento: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _languageController,
      builder: (context, _) {
        final lang = _languageController.currentLanguage;
        final strings = AppStrings.of(lang);

        return Scaffold(
          // Sfondo: degradé verticale calda, dal Corten chiarissimo in
          // alto al bianco in basso — dà calore senza essere invadente.
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFDF0EB), Colors.white],
                stops: [0.0, 0.55],
              ),
            ),
            child: SafeArea(
              child: _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _catalog == null
                      ? const Center(child: CircularProgressIndicator())
                      : _catalog!.isEmpty
                          ? Center(child: Text(strings.startActivity))
                          : _catalog!.length == 1
                              // Un solo circuito: Home dedicata, protagonista
                              ? _SingleCircuitHome(
                                  summary: _catalog!.first,
                                  languageController: _languageController,
                                  ttsService: widget.ttsService,
                                  strings: strings,
                                  lang: lang,
                                )
                              // Più circuiti: lista/catalogo
                              : _CatalogHome(
                                  catalog: _catalog!,
                                  languageController: _languageController,
                                  ttsService: widget.ttsService,
                                  strings: strings,
                                  lang: lang,
                                ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home con un solo circuito: Ferraronda è protagonista
// ─────────────────────────────────────────────────────────────────────────────
class _SingleCircuitHome extends StatelessWidget {
  final CircuitSummary summary;
  final LanguageController languageController;
  final TtsService ttsService;
  final AppStrings strings;
  final String lang;

  static const _cortenColor = Color(0xFFB7472A);

  const _SingleCircuitHome({
    required this.summary,
    required this.languageController,
    required this.ttsService,
    required this.strings,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(summary.themeColorValue);
    final iconPath = summary.iconAssetPath();
    final appStrings = AppStrings.of(lang);

    return Column(
      children: [
        // ── Barra superiore: lingue + settings ──────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LanguageChips(languageController: languageController),
              IconButton(
                icon: Icon(Icons.tune, color: Colors.grey.shade500, size: 22),
                onPressed: () async {
                  final circuit = await CircuitLoader.loadCircuit(summary.circuitId);
                  if (!context.mounted) return;
                  Navigator.of(context).push(_slideRoute(SettingsScreen(
                    languageController: languageController,
                    ttsService: ttsService,
                    circuit: circuit,
                  )));
                },
              ),
            ],
          ),
        ),

        // ── Contenuto centrale: logo + nomi ─────────────────────────────
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo grande
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: iconPath != null
                      ? Image.asset(iconPath, fit: BoxFit.cover)
                      : Image.asset('assets/images/logo_ronda.png',
                          fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 32),

              // Nome circuito — protagonista
              Text(
                summary.name.toUpperCase(),
                style: TextStyle(
                  color: themeColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5,
                ),
              ),

              const SizedBox(height: 8),

              // Sottotitolo circuito
              Text(
                summary.subtitleFor(lang),
                style: const TextStyle(
                  color: Color(0xFF6B4C3B),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Brand ombrello — discreto
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    appStrings.appName,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 30,
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Pulsanti azione ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            children: [
              // Primario: Inizia percorso
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: themeColor.withOpacity(0.5),
                  ),
                  onPressed: () async {
                    final circuit =
                        await CircuitLoader.loadCircuit(summary.circuitId);
                    if (!context.mounted) return;
                    Navigator.of(context).push(_slideRoute(MapScreen(
                      circuit: circuit,
                      languageController: languageController,
                      ttsService: ttsService,
                    )));
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: Text(
                    strings.startActivity,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondario: Esplora
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeColor,
                    side: BorderSide(color: themeColor.withOpacity(0.6), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final circuit =
                        await CircuitLoader.loadCircuit(summary.circuitId);
                    if (!context.mounted) return;
                    Navigator.of(context).push(_slideRoute(PoiListScreen(
                      circuit: circuit,
                      languageController: languageController,
                      ttsService: ttsService,
                    )));
                  },
                  icon: const Icon(Icons.explore_outlined, size: 20),
                  label: Text(
                    strings.browsePoi,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home catalogo (più circuiti) — stile card lista
// ─────────────────────────────────────────────────────────────────────────────
class _CatalogHome extends StatelessWidget {
  final List<CircuitSummary> catalog;
  final LanguageController languageController;
  final TtsService ttsService;
  final AppStrings strings;
  final String lang;

  const _CatalogHome({
    required this.catalog,
    required this.languageController,
    required this.ttsService,
    required this.strings,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header compatto con logo Ronda Stories
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Image.asset('assets/images/logo_ronda.png', width: 32, height: 32),
              const SizedBox(width: 10),
              Text(
                AppStrings.of(lang).appName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _LanguageChips(languageController: languageController),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: catalog.length,
            itemBuilder: (context, index) => _CircuitCard(
              summary: catalog[index],
              languageController: languageController,
              ttsService: ttsService,
              strings: strings,
              lang: lang,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card singolo circuito nel catalogo
// ─────────────────────────────────────────────────────────────────────────────
class _CircuitCard extends StatelessWidget {
  final CircuitSummary summary;
  final LanguageController languageController;
  final TtsService ttsService;
  final AppStrings strings;
  final String lang;

  const _CircuitCard({
    required this.summary,
    required this.languageController,
    required this.ttsService,
    required this.strings,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(summary.themeColorValue);
    final iconPath = summary.iconAssetPath();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, themeColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: ClipOval(
                        child: iconPath != null
                            ? Image.asset(iconPath, fit: BoxFit.cover)
                            : Image.asset('assets/images/logo_ronda.png',
                                fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(summary.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          Text(summary.subtitleFor(lang),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final circuit = await CircuitLoader.loadCircuit(
                              summary.circuitId);
                          if (!context.mounted) return;
                          Navigator.of(context).push(_slideRoute(MapScreen(
                            circuit: circuit,
                            languageController: languageController,
                            ttsService: ttsService,
                          )));
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(strings.startActivity),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeColor,
                          side: BorderSide(color: themeColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final circuit = await CircuitLoader.loadCircuit(
                              summary.circuitId);
                          if (!context.mounted) return;
                          Navigator.of(context)
                              .push(_slideRoute(PoiListScreen(
                            circuit: circuit,
                            languageController: languageController,
                            ttsService: ttsService,
                          )));
                        },
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: Text(strings.browsePoi),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selettore lingua compatto (chip orizzontali)
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageChips extends StatelessWidget {
  final LanguageController languageController;
  static const _uiLanguages = ['it', 'en', 'zh'];

  const _LanguageChips({required this.languageController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _uiLanguages.map((lang) {
            final isSelected = lang == languageController.currentLanguage;
            return GestureDetector(
              onTap: () => languageController.setLanguage(lang),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFB7472A)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFB7472A)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  lang.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// Transizione slide + fade
Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: animation.drive(tween),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
