import 'poi_localized_content.dart';

/// Un singolo punto di interesse lungo il percorso.
/// Il numero d'ordine NON è nel JSON — viene assegnato dal CircuitLoader
/// in base alla posizione nell'array, così aggiungere un POI non richiede
/// rinumerare tutto: basta inserirlo nel punto giusto dell'array.
class Poi {
  final String id;

  /// Numero d'ordine 1-based, assegnato dal CircuitLoader in base
  /// alla posizione nell'array JSON (non salvato nel JSON).
  final int order;

  final double lat;
  final double lon;
  final double? alt;
  final double triggerRadiusM;
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

  factory Poi.fromJson(Map<String, dynamic> json, {required int order}) {
    final contentJson = json['content'] as Map<String, dynamic>;
    final content = contentJson.map(
      (langCode, value) => MapEntry(
        langCode,
        PoiLocalizedContent.fromJson(value as Map<String, dynamic>),
      ),
    );

    return Poi(
      id: json['id'] as String,
      order: order,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      alt: (json['alt'] as num?)?.toDouble(),
      triggerRadiusM: (json['trigger_radius_m'] as num).toDouble(),
      content: content,
    );
  }

  PoiLocalizedContent contentFor(String languageCode) {
    return content[languageCode] ?? content['it']!;
  }
}
