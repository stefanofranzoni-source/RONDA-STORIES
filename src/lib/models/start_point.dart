/// Punto di partenza/arrivo del circuito (es. il parcheggio Ex MOF).
class StartPoint {
  final double lat;
  final double lon;
  final double? alt; // altitudine in metri, opzionale (vedi nota in Poi)
  final String label;

  const StartPoint({
    required this.lat,
    required this.lon,
    this.alt,
    required this.label,
  });

  factory StartPoint.fromJson(Map<String, dynamic> json) {
    return StartPoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      alt: (json['alt'] as num?)?.toDouble(),
      label: json['label'] as String,
    );
  }
}
