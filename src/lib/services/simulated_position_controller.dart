import 'package:flutter/foundation.dart';
import '../models/circuit.dart';
import '../models/poi.dart';
import 'geo_utils.dart';

/// Simula la posizione dell'utente lungo il percorso, SENZA usare il GPS
/// reale. Costruisce internamente un "percorso virtuale" che collega in
/// linea retta: partenza -> POI 1 -> POI 2 -> ... -> ultimo POI.
///
/// Un valore "progress" da 0.0 a 1.0 rappresenta quanto cammino è stato
/// fatto lungo questo percorso virtuale (0 = punto di partenza,
/// 1 = ultimo POI). Muovendo uno slider nella UI, cambiamo "progress" e
/// quindi la posizione simulata, esattamente come farebbe un vero
/// spostamento GPS.
///
/// In Fase 3 sostituiremo semplicemente la SORGENTE della posizione
/// (da questo simulatore al GPS vero), ma la logica di trigger dei POI
/// che useremo nella UI resterà identica: è per questo che vale la pena
/// separare bene "da dove arriva la posizione" da "cosa facciamo con essa".
class SimulatedPositionController extends ChangeNotifier {
  final Circuit circuit;

  double _progress = 0.0; // 0.0 .. 1.0
  double _currentLat;
  double _currentLon;

  // Tiene traccia di quali POI sono attualmente "scattati". Il
  // comportamento quando si esce dal raggio dipende da
  // circuit.poiRetrigger (vedi _checkPoiTriggers).
  final Set<String> _triggeredPoiIds = {};

  // Callback invocata quando un nuovo POI scatta. La UI (la schermata
  // mappa) si registra qui per sapere quando mostrare il popup.
  void Function(Poi poi)? onPoiTriggered;

  SimulatedPositionController(this.circuit)
      : _currentLat = circuit.startPoint.lat,
        _currentLon = circuit.startPoint.lon;

  double get progress => _progress;
  double get currentLat => _currentLat;
  double get currentLon => _currentLon;

  /// Lista ordinata dei punti che compongono il percorso virtuale:
  /// partenza + tutti i POI in ordine.
  List<({double lat, double lon})> get _routePoints {
    final points = <({double lat, double lon})>[
      (lat: circuit.startPoint.lat, lon: circuit.startPoint.lon),
    ];
    for (final poi in circuit.poi) {
      points.add((lat: poi.lat, lon: poi.lon));
    }
    return points;
  }

  /// Esposto per disegnare la linea del percorso sulla mappa.
  List<({double lat, double lon})> get routePoints => _routePoints;

  /// Aggiorna la posizione simulata in base al nuovo valore di progress
  /// (atteso tra 0.0 e 1.0, tipicamente proveniente da uno Slider).
  void setProgress(double newProgress) {
    _progress = newProgress.clamp(0.0, 1.0);

    final points = _routePoints;
    final segmentCount = points.length - 1;

    if (segmentCount <= 0) {
      notifyListeners();
      return;
    }

    // Troviamo in quale "segmento" del percorso ci troviamo e
    // interpoliamo linearmente la posizione tra i due estremi del
    // segmento. Es: con 3 segmenti, progress 0.5 cade a metà del 2°.
    final scaledProgress = _progress * segmentCount;
    final segmentIndex = scaledProgress.floor().clamp(0, segmentCount - 1);
    final segmentLocalProgress = scaledProgress - segmentIndex;

    final from = points[segmentIndex];
    final to = points[segmentIndex + 1];

    _currentLat = from.lat + (to.lat - from.lat) * segmentLocalProgress;
    _currentLon = from.lon + (to.lon - from.lon) * segmentLocalProgress;

    _checkPoiTriggers();

    notifyListeners();
  }

  void _checkPoiTriggers() {
    for (final poi in circuit.poi) {
      final distance = GeoUtils.distanceInMeters(
        lat1: _currentLat,
        lon1: _currentLon,
        lat2: poi.lat,
        lon2: poi.lon,
      );

      final isInsideRadius = distance <= poi.triggerRadiusM;
      final alreadyTriggered = _triggeredPoiIds.contains(poi.id);

      if (isInsideRadius && !alreadyTriggered) {
        _triggeredPoiIds.add(poi.id);
        onPoiTriggered?.call(poi);
      }

      // Se l'utente esce dal raggio, decidiamo se "ri-armare" il trigger
      // in base all'impostazione del circuito (poi_retrigger nel JSON):
      // - true  -> rientrando nel raggio (es. tornando indietro con lo
      //            slider, o nella realtà ripassando dallo stesso punto)
      //            il pannello informativo ricompare.
      // - false -> un POI mostrato una volta resta "consumato" per tutta
      //            la durata dell'attività, anche se si esce e si rientra
      //            dal suo raggio.
      if (!isInsideRadius && alreadyTriggered && circuit.poiRetrigger) {
        _triggeredPoiIds.remove(poi.id);
      }
    }
  }
}
