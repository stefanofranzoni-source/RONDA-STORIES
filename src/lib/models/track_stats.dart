/// Istantanea delle statistiche di un'attività di camminata/corsa in corso.
/// È un semplice "value object": non contiene logica, solo dati, pensato
/// per essere passato alla UI così com'è (un po' come una struct in C++).
class TrackStats {
  final Duration elapsed; // tempo trascorso da quando è iniziato il tracking
  final double distanceMeters; // distanza cumulata percorsa
  final double currentSpeedKmh; // velocità istantanea (ultimo tratto)
  final double averageSpeedKmh; // velocità media sull'intera attività

  const TrackStats({
    required this.elapsed,
    required this.distanceMeters,
    required this.currentSpeedKmh,
    required this.averageSpeedKmh,
  });

  /// Stato iniziale, prima che il tracking cominci o subito dopo l'avvio.
  factory TrackStats.zero() {
    return const TrackStats(
      elapsed: Duration.zero,
      distanceMeters: 0,
      currentSpeedKmh: 0,
      averageSpeedKmh: 0,
    );
  }

  double get distanceKm => distanceMeters / 1000.0;
}
