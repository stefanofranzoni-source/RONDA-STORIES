import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/circuit.dart';
import '../models/poi.dart';
import 'geo_utils.dart';
import 'track_recorder.dart';

/// Stato del servizio GPS: utile alla UI per mostrare messaggi appropriati
/// a seconda della situazione (es. "Attivazione GPS..." invece di una
/// mappa ferma senza spiegazione).
enum GpsStatus {
  idle,          // non ancora avviato
  requesting,    // stiamo richiedendo il permesso all'utente
  active,        // posizione in arrivo regolarmente
  permissionDenied,    // l'utente ha negato il permesso
  locationDisabled,    // GPS spento nelle impostazioni di sistema
  error,         // errore generico
}

/// Controller GPS reale: legge la posizione dal sensore del telefono,
/// gestisce i permessi, notifica i trigger dei POI e alimenta il
/// TrackRecorder con i punti reali.
///
/// Questa classe ha la stessa interfaccia "osservabile" del
/// SimulatedPositionController (estende ChangeNotifier, espone currentLat/
/// currentLon, onPoiTriggered) in modo che la MapScreen possa usare
/// entrambi in modo intercambiabile.
class GeoPositionController extends ChangeNotifier {
  final Circuit circuit;
  final TrackRecorder trackRecorder;

  GpsStatus _gpsStatus = GpsStatus.idle;
  GpsStatus get gpsStatus => _gpsStatus;

  double _currentLat;
  double _currentLon;
  double? _currentAlt;
  double _currentAccuracyM = 0;

  double get currentLat => _currentLat;
  double get currentLon => _currentLon;
  double? get currentAlt => _currentAlt;
  double get currentAccuracyM => _currentAccuracyM;

  // Callback invocata quando un POI entra nel raggio: la MapScreen
  // si registra qui per mostrare il pannello informativo.
  void Function(Poi poi)? onPoiTriggered;

  final Set<String> _triggeredPoiIds = {};
  StreamSubscription<Position>? _positionSubscription;

  GeoPositionController(this.circuit, this.trackRecorder)
      : _currentLat = circuit.startPoint?.lat ?? circuit.poi.first.lat,
        _currentLon = circuit.startPoint?.lon ?? circuit.poi.first.lon;

  /// Avvia il tracking GPS: richiede il permesso se necessario, poi
  /// inizia ad ascoltare gli aggiornamenti di posizione dal sensore.
  Future<void> start() async {
    _gpsStatus = GpsStatus.requesting;
    notifyListeners();

    // 1. Controlla se il servizio di localizzazione è abilitato nel
    //    sistema (il GPS del telefono è acceso?).
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _gpsStatus = GpsStatus.locationDisabled;
      notifyListeners();
      return;
    }

    // 2. Controlla/richiedi il permesso di accesso alla posizione.
    //    Su Android, la prima volta che viene chiamato, mostra
    //    automaticamente il popup di sistema "Consenti a Ferraronda
    //    di accedere alla posizione?".
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _gpsStatus = GpsStatus.permissionDenied;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // L'utente ha scelto "Non chiedere più": non possiamo mostrare
      // di nuovo il popup, dobbiamo mandarlo alle impostazioni di sistema.
      _gpsStatus = GpsStatus.permissionDenied;
      notifyListeners();
      return;
    }

    // 3. Permesso ottenuto: inizia lo stream di posizioni.
    //    LocationSettings calibra il trade-off tra precisione e
    //    consumo batteria:
    //    - accuracy: best = massima precisione (usa GPS + WiFi + rete)
    //    - distanceFilter: 3 = notifica solo se ci si è spostati di
    //      almeno 3 metri, evita aggiornamenti inutili da "jitter" GPS
    //      mentre si è fermi.
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
    );

    _gpsStatus = GpsStatus.active;
    notifyListeners();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        debugPrint('[GPS] Errore stream posizione: $error');
        _gpsStatus = GpsStatus.error;
        notifyListeners();
      },
    );
  }

  void _onPositionUpdate(Position position) {
    _currentLat = position.latitude;
    _currentLon = position.longitude;
    _currentAlt = position.altitude;
    _currentAccuracyM = position.accuracy;

    // Alimenta il TrackRecorder con il punto reale.
    trackRecorder.addPoint(
      lat: position.latitude,
      lon: position.longitude,
      alt: position.altitude,
    );

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

      if (!isInsideRadius && alreadyTriggered && circuit.poiRetrigger) {
        _triggeredPoiIds.remove(poi.id);
      }
    }
  }

  /// Ferma lo stream GPS e cancella lo stato di trigger.
  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _triggeredPoiIds.clear();
    _gpsStatus = GpsStatus.idle;
    notifyListeners();
  }

  /// Apre le impostazioni di sistema del dispositivo, utile quando
  /// il permesso è stato negato definitivamente o il GPS è spento.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
