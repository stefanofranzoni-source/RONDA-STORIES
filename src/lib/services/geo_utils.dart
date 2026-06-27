import 'dart:math' as math;

/// Funzioni geografiche di utilità, riusate sia per il trigger dei POI
/// (Fase 2) sia per le statistiche di tracking come distanza/velocità
/// (Fase 3). Tenerle in un punto solo evita di duplicare la matematica.
///
/// Importiamo dart:math con il prefisso "math." (es. math.sin, math.cos)
/// per evitare ambiguità con eventuali altre funzioni chiamate allo
/// stesso modo altrove nel progetto: è una pratica comune in Dart,
/// concettualmente simile a usare un namespace esplicito in C++
/// (std::sin invece di un "using namespace std" indiscriminato).
class GeoUtils {
  /// Calcola la distanza in METRI tra due coordinate GPS usando la
  /// formula dell'haversine (tiene conto della curvatura terrestre,
  /// accurata a sufficienza per le distanze "a piedi" che ci interessano).
  static double distanceInMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusM = 6371000.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadiusM * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}
