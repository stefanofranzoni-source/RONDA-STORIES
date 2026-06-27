import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/track_stats.dart';
import 'geo_utils.dart';

/// Un singolo punto registrato durante un'attività: posizione + istante
/// in cui è stata rilevata.
class TrackPoint {
  final double lat;
  final double lon;

  /// Altitudine in metri, opzionale: il simulatore via slider non la
  /// fornisce (resta null), ma il GPS reale del telefono sì. Non ancora
  /// usata nei calcoli di TrackStats: predisposta per un eventuale futuro
  /// calcolo di dislivello positivo/negativo cumulato.
  final double? alt;

  final DateTime timestamp;

  const TrackPoint({
    required this.lat,
    required this.lon,
    this.alt,
    required this.timestamp,
  });
}

/// Registra una "traccia" (un'attività: camminata lungo il circuito) e
/// calcola in tempo reale tempo trascorso, distanza percorsa e velocità.
///
/// Il punto IMPORTANTE per il riuso: questa classe non sa nulla di GPS,
/// slider, o simulazioni. Riceve semplicemente punti via addPoint() e fa
/// di conto. Che il chiamante prenda i punti da uno slider (come adesso)
/// o da un vero sensore GPS (più avanti) per questa classe non cambia
/// nulla — è esattamente questo disaccoppiamento che ci risparmia di
/// riscrivere la logica di tracking quando passeremo al GPS reale.
class TrackRecorder extends ChangeNotifier {
  final List<TrackPoint> _points = [];
  bool _isRunning = false;
  bool _isPaused = false;

  TrackStats _stats = TrackStats.zero();

  Timer? _ticker;
  DateTime? _startTime;

  // Tempo accumulato prima della pausa — sommato a quello corrente
  // per avere il totale elapsed anche dopo pause/resume multipli.
  Duration _elapsedBeforePause = Duration.zero;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isActive => _isRunning && !_isPaused; // sta registrando davvero
  TrackStats get stats => _stats;
  List<TrackPoint> get points => List.unmodifiable(_points);

  /// Avvia una nuova registrazione azzerando tutto.
  /// Il reset avviene automaticamente rientrando nella mappa
  /// (MapScreen crea una nuova istanza ad ogni apertura).
  void start() {
    _points.clear();
    _stats = TrackStats.zero();
    _isRunning = true;
    _isPaused = false;
    _elapsedBeforePause = Duration.zero;
    _startTime = DateTime.now();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && !_isPaused) {
        _recomputeStats();
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Mette in pausa: il cronometro si ferma, i dati restano.
  /// Riprendi con resume().
  void pause() {
    if (!_isRunning || _isPaused) return;
    // Salva il tempo accumulato fino a ora
    if (_startTime != null) {
      _elapsedBeforePause += DateTime.now().difference(_startTime!);
    }
    _isPaused = true;
    _startTime = null;
    notifyListeners();
  }

  /// Riprende dopo una pausa.
  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _startTime = DateTime.now();
    notifyListeners();
  }

  /// Ferma definitivamente la registrazione (usato solo nel dispose).
  void stop() {
    _isRunning = false;
    _isPaused = false;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  /// Azzera tutti i dati senza avviare una nuova registrazione.
  /// Usato per il reset esplicito (doppio tap sul pulsante in pausa).
  void reset() {
    _ticker?.cancel();
    _ticker = null;
    _isRunning = false;
    _isPaused = false;
    _points.clear();
    _elapsedBeforePause = Duration.zero;
    _startTime = null;
    _stats = TrackStats.zero();
    notifyListeners();
  }

  /// Aggiunge un nuovo punto rilevato e ricalcola le statistiche.
  /// Va chiamato ogni volta che la posizione "corrente" cambia (sia che
  /// arrivi dallo slider simulato, sia in futuro dal GPS).
  ///
  /// Ignoriamo punti troppo vicini al precedente (< minDistanceMeters):
  /// con la simulazione via slider, trascinando si generano molti eventi
  /// ravvicinati nello spazio e nel tempo, che farebbero impennare in modo
  /// irrealistico il calcolo della velocità istantanea. Con il GPS reale
  /// questo filtro resterà utile comunque, per ignorare il "rumore" del
  /// sensore quando si è fermi.
  static const double _minDistanceMeters = 3.0;

  void addPoint({
    required double lat,
    required double lon,
    double? alt,
    DateTime? timestamp,
  }) {
    if (!_isRunning || _isPaused) return; // ignora punti durante la pausa

    final newTimestamp = timestamp ?? DateTime.now();

    if (_points.isNotEmpty) {
      final last = _points.last;
      final distanceFromLast = GeoUtils.distanceInMeters(
        lat1: last.lat,
        lon1: last.lon,
        lat2: lat,
        lon2: lon,
      );
      if (distanceFromLast < _minDistanceMeters) return;
    }

    final point = TrackPoint(
      lat: lat,
      lon: lon,
      alt: alt,
      timestamp: newTimestamp,
    );

    _points.add(point);
    _recomputeStats();
    notifyListeners();
  }

  void _recomputeStats() {
    // Tempo totale = accumulato prima delle pause + tempo dall'ultimo resume
    final currentSegment = (_startTime != null && !_isPaused)
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;
    final elapsed = _elapsedBeforePause + currentSegment;

    if (_points.isEmpty) {
      _stats = TrackStats(
        elapsed: elapsed,
        distanceMeters: 0,
        currentSpeedKmh: 0,
        averageSpeedKmh: 0,
      );
      return;
    }

    double totalDistanceM = 0;
    double lastSegmentDistanceM = 0;
    Duration lastSegmentDuration = Duration.zero;

    for (var i = 1; i < _points.length; i++) {
      final prev = _points[i - 1];
      final curr = _points[i];

      final segmentDistance = GeoUtils.distanceInMeters(
        lat1: prev.lat,
        lon1: prev.lon,
        lat2: curr.lat,
        lon2: curr.lon,
      );

      totalDistanceM += segmentDistance;

      if (i == _points.length - 1) {
        lastSegmentDistanceM = segmentDistance;
        lastSegmentDuration = curr.timestamp.difference(prev.timestamp);
      }
    }

    final currentSpeedKmh = _speedKmh(lastSegmentDistanceM, lastSegmentDuration);
    final averageSpeedKmh = _speedKmh(totalDistanceM, elapsed);

    _stats = TrackStats(
      elapsed: elapsed,
      distanceMeters: totalDistanceM,
      currentSpeedKmh: currentSpeedKmh,
      averageSpeedKmh: averageSpeedKmh,
    );
  }

  /// Converte distanza (metri) + tempo in velocità in km/h.
  double _speedKmh(double distanceM, Duration duration) {
    final seconds = duration.inMilliseconds / 1000.0;
    if (seconds <= 0) return 0;
    final metersPerSecond = distanceM / seconds;
    return metersPerSecond * 3.6;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
