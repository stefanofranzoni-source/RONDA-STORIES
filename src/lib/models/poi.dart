import 'poi_localized_content.dart';

/// Un singolo punto di interesse lungo il percorso (es. "Porta Po").
/// Contiene la posizione GPS e il testo in tutte le lingue disponibili.
class Poi {
  final String id;
  final int order;
  final double lat;
  final double lon;

  /// Altitudine in metri (quota Z), OPZIONALE: null se non specificata
  /// nel JSON. Per Ferraronda non viene usata in nessun calcolo (il
  /// circuito è sostanzialmente pianeggiante), ma è già pronta per
  /// circuiti futuri con dislivelli, dove potrà servire a calcolare
  /// salita/discesa cumulata o a disambiguare POI sovrapposti su piani
  /// diversi.
  final double? alt;

  final double triggerRadiusM;

  // Map<lingua, contenuto>. Esempio: {"it": ..., "en": ...}
  // È l'equivalente Dart di una std::map<std::string, PoiLocalizedContent>
  final Map<String, PoiLocalizedContent> content;

  const Poi({
    required this.id,
    required this.order,
    required this.lat,
    required this.lon,
    this.alt,
    required this.triggerRadiusM,
    required this.content,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    final contentJson = json['content'] as Map<String, dynamic>;

    // Costruiamo la Map<String, PoiLocalizedContent> a partire dalla Map
    // JSON grezza. ".map()" qui è il "map funzionale" (come in tanti
    // linguaggi moderni), non c'entra con il tipo Map: trasforma ogni
    // coppia chiave/valore in una nuova coppia.
    final content = contentJson.map(
      (langCode, value) => MapEntry(
        langCode,
        PoiLocalizedContent.fromJson(value as Map<String, dynamic>),
      ),
    );

    return Poi(
      id: json['id'] as String,
      order: json['order'] as int,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      // "as num?" + "?.toDouble()" gestisce sia il caso in cui il campo
      // manchi dal JSON (json['alt'] è null) sia il caso in cui sia
      // presente come intero o decimale.
      alt: (json['alt'] as num?)?.toDouble(),
      triggerRadiusM: (json['trigger_radius_m'] as num).toDouble(),
      content: content,
    );
  }

  /// Ritorna il contenuto nella lingua richiesta, con fallback all'italiano
  /// se quella lingua non è disponibile per questo POI.
  PoiLocalizedContent contentFor(String languageCode) {
    return content[languageCode] ?? content['it']!;
  }
}
