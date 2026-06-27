import 'poi.dart';
import 'start_point.dart';

/// Comportamento del pannello informativo quando scatta un POI.
enum PoiPanelBehavior {
  /// Si apre automaticamente e si chiude dopo la lettura TTS
  /// + un ritardo configurabile (poi_auto_close_delay_s).
  auto,
  /// Si apre automaticamente, si chiude solo quando l'utente preme X.
  manual,
  /// Nessun pannello visivo: solo lettura TTS, la mappa resta libera.
  ttsOnly,
  /// Nessun pannello, nessuna voce: solo vibrazione/feedback minimo.
  silent,
}

class Circuit {
  final String circuitId;
  final String name;

  /// Nome del file icona del circuito (opzionale): se presente, il file
  /// si trova nella stessa cartella del circuit.json. Se assente, l'app
  /// usa l'icona di default di Ronda.
  final String? icon;

  final Map<String, String> subtitle;
  final List<String> languages;
  final String defaultLanguage;
  final String themeColor;
  final bool poiRetrigger;
  final PoiPanelBehavior poiPanelBehavior;
  final int poiAutoCloseDelaySec;
  final StartPoint? startPoint;

  /// Traccia del percorso reale: lista di punti lat/lon (opzionale alt)
  /// estratta dal file GPX e semplificata. Se vuota, la mappa disegna
  /// una linea diretta tra i POI come fallback.
  final List<({double lat, double lon})> route;

  final List<Poi> poi;

  /// Metadati di versione — mostrati nella schermata Settings.
  final String version;
  final String versionDate;
  final String author;

  const Circuit({
    required this.circuitId,
    required this.name,
    this.icon,
    required this.subtitle,
    required this.languages,
    required this.defaultLanguage,
    required this.themeColor,
    required this.poiRetrigger,
    required this.poiPanelBehavior,
    required this.poiAutoCloseDelaySec,
    this.startPoint,
    required this.route,
    required this.poi,
    this.version = '0.0.1',
    this.versionDate = '',
    this.author = '',
  });

  String subtitleFor(String languageCode) {
    return subtitle[languageCode] ?? subtitle['it'] ?? '';
  }

  /// Colore principale del circuito come oggetto Color Flutter.
  /// Parsato da stringa esadecimale "#RRGGBB".
  int get themeColorValue {
    final hex = themeColor.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }

  factory Circuit.fromJson(Map<String, dynamic> json) {
    // L'ordine viene dalla posizione nell'array — nessun sort necessario,
    // nessun campo "order" nel JSON da mantenere aggiornato.
    final rawPoi = json['poi'] as List<dynamic>;
    final poiList = rawPoi
        .asMap()
        .entries
        .map((e) => Poi.fromJson(
              e.value as Map<String, dynamic>,
              order: e.key + 1, // 1-based
            ))
        .toList();

    final rawSubtitle = json['subtitle'];
    final Map<String, String> subtitleMap;
    if (rawSubtitle is String) {
      subtitleMap = {'it': rawSubtitle};
    } else {
      subtitleMap = (rawSubtitle as Map<String, dynamic>)
          .map((lang, value) => MapEntry(lang, value as String));
    }

    PoiPanelBehavior behavior;
    switch (json['poi_panel_behavior'] as String? ?? 'manual') {
      case 'auto':
        behavior = PoiPanelBehavior.auto;
      case 'tts_only':
        behavior = PoiPanelBehavior.ttsOnly;
      case 'silent':
        behavior = PoiPanelBehavior.silent;
      default:
        behavior = PoiPanelBehavior.manual;
    }

    // Parsing route: lista opzionale di punti lat/lon dal GPX semplificato.
    // Se assente nel JSON, fallback a lista vuota (la mappa userà i POI).
    final rawRoute = json['route'] as List<dynamic>? ?? [];
    final route = rawRoute.map((p) {
      final m = p as Map<String, dynamic>;
      return (
        lat: (m['lat'] as num).toDouble(),
        lon: (m['lon'] as num).toDouble(),
      );
    }).toList();

    return Circuit(
      circuitId: json['circuit_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      subtitle: subtitleMap,
      languages: (json['languages'] as List<dynamic>).cast<String>(),
      defaultLanguage: json['default_language'] as String,
      themeColor: json['theme_color'] as String,
      poiRetrigger: json['poi_retrigger'] as bool? ?? true,
      poiPanelBehavior: behavior,
      poiAutoCloseDelaySec: json['poi_auto_close_delay_s'] as int? ?? 4,
      startPoint: json['start_point'] != null
          ? StartPoint.fromJson(json['start_point'] as Map<String, dynamic>)
          : null,
      route: route,
      poi: poiList,
      version: json['version'] as String? ?? '0.0.1',
      versionDate: json['version_date'] as String? ?? '',
      author: json['author'] as String? ?? '',
    );
  }
}
