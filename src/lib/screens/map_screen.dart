import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_compass/flutter_map_compass.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../models/circuit.dart';
import '../models/poi.dart';
import '../services/app_strings.dart';
import '../services/geo_position_controller.dart';
import '../services/language_controller.dart';
import '../services/track_recorder.dart';
import '../services/tts_service.dart';
import 'widgets/track_stats_panel.dart';

/// Schermata mappa con GPS reale: mostra il percorso del circuito,
/// la posizione dell'utente aggiornata in tempo reale dal sensore GPS,
/// e segue automaticamente l'utente mentre cammina (stile navigatore).
///
/// L'utente può spostare manualmente la visuale (il "follow" si sblocca),
/// e può riattivarla toccando il pulsante di centratura in basso a destra.
class MapScreen extends StatefulWidget {
  final Circuit circuit;
  final LanguageController languageController;
  final TtsService ttsService;

  const MapScreen({
    super.key,
    required this.circuit,
    required this.languageController,
    required this.ttsService,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final TrackRecorder _trackRecorder;
  late final GeoPositionController _gpsController;
  final MapController _mapController = MapController();

  bool _followUser = true;
  Poi? _activePoi;

  // Tiene traccia dei POI già visitati (trigger GPS scattato almeno una volta)
  // per mostrare il marker in stile "già letto" (grigio/opaco).
  final Set<String> _visitedPoiIds = {};

  // True quando la card è aperta da tap manuale sul marker (preview)
  // invece che da trigger GPS — in modalità preview non si segna il
  // POI come visitato e il TTS non parte automaticamente.
  bool _previewMode = false;

  // Numero di POI visitati al momento del trigger del POI attivo.
  // Usato dalla card per scegliere se mostrare il testo normale o l'altText.
  int _activePoiVisitedCount = 0;

  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();

    _trackRecorder = TrackRecorder();
    _gpsController = GeoPositionController(widget.circuit, _trackRecorder);

    _gpsController.onPoiTriggered = (poi, visitedCount) {
      final behavior = widget.circuit.poiPanelBehavior;

      // Segna il POI come visitato per aggiornare il suo marker sulla mappa
      setState(() => _visitedPoiIds.add(poi.id));

      if (behavior == PoiPanelBehavior.silent) return;

      if (behavior != PoiPanelBehavior.ttsOnly) {
        setState(() {
          _activePoi = poi;
          _previewMode = false;
          _activePoiVisitedCount = visitedCount;
        });
      }

      final lang = widget.languageController.currentLanguage;
      final localized = poi.contentFor(lang);

      // Usa altText se disponibile e se il POI è già stato visitato almeno
      // una volta (visitedCount > 0 significa che altri POI sono già stati
      // visitati prima di tornare qui — es. ritorno al punto di partenza).
      final textToRead = (visitedCount > 0 && localized.altText != null)
          ? localized.altText!
          : localized.text;

      widget.ttsService.speak(textToRead, languageCode: lang).then((_) {
        final error = widget.ttsService.lastError;
        if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      });

      if (behavior == PoiPanelBehavior.auto) {
        widget.ttsService.onSpeakCompleted = () {
          _autoCloseTimer?.cancel();
          _autoCloseTimer = Timer(
            Duration(seconds: widget.circuit.poiAutoCloseDelaySec),
            () {
              if (mounted) setState(() => _activePoi = null);
            },
          );
          widget.ttsService.onSpeakCompleted = null;
        };
      }
    };

    _gpsController.addListener(_onPositionChanged);
    _gpsController.start();
  }

  /// Chiude il pannello POI manualmente (pulsante X) e annulla
  /// l'eventuale timer di chiusura automatica in corso.
  void _closePoiPanel() {
    _autoCloseTimer?.cancel();
    widget.ttsService.onSpeakCompleted = null;
    widget.ttsService.stop();
    setState(() {
      _activePoi = null;
      _previewMode = false;
    });
  }

  /// Apre la card in modalità "preview" da tap manuale sul marker.
  /// Non segna il POI come visitato, non avvia il TTS automaticamente.
  void _openPoiPreview(Poi poi) {
    _autoCloseTimer?.cancel();
    widget.ttsService.onSpeakCompleted = null;
    widget.ttsService.stop();
    setState(() {
      _activePoi = poi;
      _previewMode = true;
      _activePoiVisitedCount = 0;
    });
  }

  void _onPositionChanged() {
    if (!_followUser) return;
    // Sposta la visuale della mappa sulla posizione corrente dell'utente,
    // mantenendo lo zoom attuale (non lo cambiamo ogni aggiornamento).
    _mapController.move(
      ll.LatLng(_gpsController.currentLat, _gpsController.currentLon),
      _mapController.camera.zoom,
    );
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    widget.ttsService.onSpeakCompleted = null;
    _gpsController.removeListener(_onPositionChanged);
    _gpsController.stop();
    _gpsController.dispose();
    _trackRecorder.dispose();
    widget.ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circuit = widget.circuit;
    // Centro mappa iniziale: startPoint se presente, altrimenti il
    // primo POI. Appena arriva il primo fix GPS la mappa si sposta
    // automaticamente sulla posizione reale dell'utente.
    final initialCenter = circuit.startPoint != null
        ? ll.LatLng(circuit.startPoint!.lat, circuit.startPoint!.lon)
        : ll.LatLng(circuit.poi.first.lat, circuit.poi.first.lon);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Torna alla home',
              )
            : Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset('assets/images/logo_ronda.png'),
              ),
        title: AnimatedBuilder(
          animation: widget.languageController,
          builder: (context, _) {
            final strings = AppStrings.of(widget.languageController.currentLanguage);
            return Text('${circuit.name}${strings.mapTitleSuffix}');
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_gpsController, _trackRecorder]),
        builder: (context, _) {
          final lang = widget.languageController.currentLanguage;
          final strings = AppStrings.of(lang);

          // Usa la traccia GPX reale se disponibile, altrimenti
          // collega i POI in ordine come fallback.
          final routeLatLngs = circuit.route.isNotEmpty
              ? circuit.route.map((p) => ll.LatLng(p.lat, p.lon)).toList()
              : circuit.poi.map((p) => ll.LatLng(p.lat, p.lon)).toList();

          final userPosition = ll.LatLng(
            _gpsController.currentLat,
            _gpsController.currentLon,
          );

          return Column(
            children: [
              // Banner di stato GPS (visibile solo se il GPS non è attivo)
              if (_gpsController.gpsStatus != GpsStatus.active)
                _GpsStatusBanner(
                  status: _gpsController.gpsStatus,
                  onOpenSettings: _gpsController.openLocationSettings,
                  onOpenAppSettings: _gpsController.openAppSettings,
                ),

              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 16,
                        // Quando l'utente tocca/trascina la mappa,
                        // disattiviamo il follow automatico.
                        onPositionChanged: (_, hasGesture) {
                          if (hasGesture && _followUser) {
                            setState(() => _followUser = false);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ronda.stories',
                        ),
                        // Percorso previsto — bordo bianco sottile per
                        // staccare il Corten dallo sfondo della mappa.
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routeLatLngs,
                              strokeWidth: 6,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            Polyline(
                              points: routeLatLngs,
                              strokeWidth: 3.5,
                              color: const Color(0xFFB7472A),
                            ),
                          ],
                        ),
                        // Traccia reale dell'utente (blu, stesso stile)
                        if (_trackRecorder.points.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _trackRecorder.points
                                    .map((p) => ll.LatLng(p.lat, p.lon))
                                    .toList(),
                                strokeWidth: 6,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              Polyline(
                                points: _trackRecorder.points
                                    .map((p) => ll.LatLng(p.lat, p.lon))
                                    .toList(),
                                strokeWidth: 3.5,
                                color: Colors.blue.shade600,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            // Marker personalizzati per ogni POI
                            for (final poi in circuit.poi)
                              Marker(
                                point: ll.LatLng(poi.lat, poi.lon),
                                width: 44,
                                height: 52,
                                alignment: Alignment.bottomCenter,
                                child: GestureDetector(
                                  onTap: () => _openPoiPreview(poi),
                                  child: _PoiMarker(
                                    poi: poi,
                                    isVisited: _visitedPoiIds.contains(poi.id),
                                    isActive: _activePoi?.id == poi.id,
                                  ),
                                ),
                              ),
                            // Marker utente con cerchio di accuratezza
                            Marker(
                              point: userPosition,
                              width: 32,
                              height: 32,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue.withOpacity(0.2),
                                    ),
                                  ),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Bussola sempre visibile — mostra il nord,
                        // ruota con la mappa, toccandola riporta al nord.
                        const MapCompass.cupertino(
                          hideIfRotatedNorth: false,
                          alignment: Alignment.topRight,
                          padding: EdgeInsets.fromLTRB(0, 80, 10, 0),
                        ),
                      ],
                    ),

                    // Card informativa POI
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ));
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: _activePoi != null
                            ? Padding(
                                key: ValueKey(_activePoi!.id),
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: _PoiInfoCard(
                                  poi: _activePoi!,
                                  totalPoi: circuit.poi.length,
                                  isPreview: _previewMode,
                                  visitedCount: _activePoiVisitedCount,
                                  languageController: widget.languageController,
                                  ttsService: widget.ttsService,
                                  strings: strings,
                                  onClose: _closePoiPanel,
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                    ),

                    // appare solo quando il follow è disattivato
                    // E la card POI non è aperta (evita sovrapposizioni).
                    if (!_followUser && _activePoi == null)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'recenter',
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB7472A),
                          elevation: 4,
                          onPressed: () {
                            setState(() => _followUser = true);
                            _mapController.move(
                              ll.LatLng(
                                _gpsController.currentLat,
                                _gpsController.currentLon,
                              ),
                              16,
                            );
                          },
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                  ],
                ),
              ),

              // Barra inferiore: statistiche + pulsante Start/Stop tracking
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: TrackStatsPanel(
                          stats: _trackRecorder.stats,
                          strings: strings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Pulsante debug: apre Google Maps centrato
                      // sulla posizione GPS corrente — utile per
                      // prendere coordinate precise dei POI sul campo.
                      // Indicatore accuratezza GPS
                      if (_gpsController.gpsStatus == GpsStatus.active)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.gps_fixed, size: 14),
                              Text(
                                '±${_gpsController.currentAccuracyM.toStringAsFixed(0)}m',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      // Pulsante tracking: tre stati
                      // ▶ Avvia (non started) → ⏸ Pausa (running) → ▶ Riprendi (paused)
                      // Doppio tap su ▶ arancione (in pausa) → reset
                      if (!_trackRecorder.isRunning)
                        IconButton.filled(
                          onPressed: () => _trackRecorder.start(),
                          icon: const Icon(Icons.play_arrow_rounded),
                          tooltip: strings.startActivity,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFB7472A),
                            foregroundColor: Colors.white,
                          ),
                        )
                      else if (_trackRecorder.isPaused)
                        GestureDetector(
                          onDoubleTap: () {
                            _trackRecorder.reset();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(strings.trackingReset),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: IconButton.filled(
                            onPressed: () => _trackRecorder.resume(),
                            icon: const Icon(Icons.play_arrow_rounded),
                            tooltip: strings.doubleTapToReset,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        )
                      else
                        IconButton.outlined(
                          onPressed: () => _trackRecorder.pause(),
                          icon: const Icon(Icons.pause_rounded),
                          tooltip: strings.pause,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Banner mostrato nella parte alta della schermata quando il GPS
/// non è ancora attivo, ha un problema di permessi, o è disabilitato.

/// Marker personalizzato per un POI sulla mappa.
/// Tre varianti visive:
/// - Partenza/Arrivo (order==16 o id=="partenza"): bandierina
/// - Normale: pin Corten con numero bianco
/// - Visitato: stesso pin ma grigio/opaco
class _PoiMarker extends StatelessWidget {
  final Poi poi;
  final bool isVisited;
  final bool isActive; // POI attualmente mostrato nel pannello

  static const _cortenColor = Color(0xFFB7472A);
  static const _visitedColor = Color(0xFF9E9E9E);
  static const _activeColor = Color(0xFFD4572A);

  const _PoiMarker({
    required this.poi,
    required this.isVisited,
    required this.isActive,
  });

  bool get _isStartEnd => poi.id == 'partenza';

  @override
  Widget build(BuildContext context) {
    if (_isStartEnd) {
      return _buildStartEndMarker();
    }
    return _buildPinMarker();
  }

  /// Marker bandierina per il punto di partenza/arrivo
  Widget _buildStartEndMarker() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Asta
        Positioned(
          bottom: 0,
          child: Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: isVisited ? _visitedColor : _cortenColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Bandierina
        Positioned(
          top: 0,
          left: 3,
          child: Container(
            width: 26,
            height: 18,
            decoration: BoxDecoration(
              color: isVisited ? _visitedColor : _cortenColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.flag, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }

  /// Marker pin a goccia con numero per i POI normali
  Widget _buildPinMarker() {
    final color = isActive
        ? _activeColor
        : isVisited
            ? _visitedColor
            : _cortenColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Testa del pin: cerchio con numero
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${poi.order}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
        // Punta del pin (triangolino)
        CustomPaint(
          size: const Size(12, 8),
          painter: _PinTipPainter(color: color),
        ),
      ],
    );
  }
}

/// Disegna la punta triangolare del pin marker
class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTipPainter old) => old.color != color;
}

/// Banner mostrato nella parte alta della schermata quando il GPS
/// non è ancora attivo, ha un problema di permessi, o è disabilitato.
class _GpsStatusBanner extends StatelessWidget {
  final GpsStatus status;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAppSettings;

  const _GpsStatusBanner({
    required this.status,
    required this.onOpenSettings,
    required this.onOpenAppSettings,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    VoidCallback? action;
    String? actionLabel;

    switch (status) {
      case GpsStatus.requesting:
        message = 'Attivazione GPS in corso...';
        icon = Icons.gps_not_fixed;
      case GpsStatus.locationDisabled:
        message = 'GPS disattivato. Attivalo nelle impostazioni.';
        icon = Icons.location_disabled;
        action = onOpenSettings;
        actionLabel = 'Impostazioni';
      case GpsStatus.permissionDenied:
        message = 'Permesso posizione negato.';
        icon = Icons.location_off;
        action = onOpenAppSettings;
        actionLabel = 'Autorizza';
      case GpsStatus.error:
        message = 'Errore GPS. Riprova.';
        icon = Icons.error_outline;
      default:
        message = 'In attesa del GPS...';
        icon = Icons.gps_not_fixed;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: action,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Card informativa non modale mostrata in overlay sopra la mappa
/// quando un POI scatta. Design essenziale ma curato:
/// intestazione Corten con numero e titolo, corpo bianco con
/// testo leggibile outdoor, pulsante Ascolta prominente.
/// Il testo scorre automaticamente mentre la voce legge.
class _PoiInfoCard extends StatefulWidget {
  final Poi poi;
  final int totalPoi;
  final bool isPreview;
  final int visitedCount;
  final LanguageController languageController;
  final TtsService ttsService;
  final AppStrings strings;
  final VoidCallback onClose;

  static const cortenColor = Color(0xFFB7472A);

  const _PoiInfoCard({
    required this.poi,
    required this.totalPoi,
    required this.isPreview,
    required this.visitedCount,
    required this.languageController,
    required this.ttsService,
    required this.strings,
    required this.onClose,
  });

  @override
  State<_PoiInfoCard> createState() => _PoiInfoCardState();
}

class _PoiInfoCardState extends State<_PoiInfoCard> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  static const _cortenColor = Color(0xFFB7472A);

  @override
  void initState() {
    super.initState();
    widget.ttsService.addListener(_onTtsChanged);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    widget.ttsService.removeListener(_onTtsChanged);
    super.dispose();
  }

  void _onTtsChanged() {
    if (widget.ttsService.isSpeaking) {
      _startScrollAnimation();
    } else {
      _stopScrollAnimation();
    }
  }

  void _startScrollAnimation() {
    _scrollTimer?.cancel();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    final lang = widget.languageController.currentLanguage;
    final localized = widget.poi.contentFor(lang);
    final displayText = (widget.visitedCount > 0 && localized.altText != null)
        ? localized.altText!
        : localized.text;

    // Stima durata lettura: ~13 caratteri al secondo alla velocità 0.45
    // proporzionale alla speechRate corrente
    final rate = widget.ttsService.speechRate;
    final charsPerSecond = 13.0 * (rate / 0.45);
    final estimatedMs = (displayText.length / charsPerSecond * 1000).round();

    // Aggiorniamo la posizione scroll ogni 100ms proporzionalmente
    const intervalMs = 100;
    int elapsed = 0;

    _scrollTimer = Timer.periodic(
      const Duration(milliseconds: intervalMs),
      (timer) {
        elapsed += intervalMs;
        if (!_scrollController.hasClients || !widget.ttsService.isSpeaking) {
          timer.cancel();
          return;
        }
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll <= 0) return;

        final progress = (elapsed / estimatedMs).clamp(0.0, 1.0);
        _scrollController.animateTo(
          maxScroll * progress,
          duration: const Duration(milliseconds: 120),
          curve: Curves.linear,
        );

        if (elapsed >= estimatedMs) timer.cancel();
      },
    );
  }

  void _stopScrollAnimation() {
    _scrollTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.languageController, widget.ttsService]),
      builder: (context, _) {
        final lang = widget.languageController.currentLanguage;
        final localized = widget.poi.contentFor(lang);
        final isSpeaking = widget.ttsService.isSpeaking;

        // Usa altText se il POI è stato già visitato e l'altText è disponibile
        final displayText = (widget.visitedCount > 0 && localized.altText != null)
            ? localized.altText!
            : localized.text;

        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black38,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Intestazione colorata Corten
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    color: _cortenColor,
                    child: Row(
                      children: [
                        // Badge: numero POI oppure "Anteprima"
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.isPreview ? '👁 Anteprima' : '${widget.poi.order} · ${widget.totalPoi}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            localized.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32,
                          ),
                          tooltip: widget.strings.close,
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ),

                  // Corpo: testo con scroll animato durante TTS
                  Flexible(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      physics: isSpeaking
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.55,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    ),
                  ),

                  // Footer: pulsante Ascolta
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: isSpeaking
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _cortenColor,
                                side: const BorderSide(color: _cortenColor),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => widget.ttsService.stop(),
                              icon: const Icon(Icons.stop_rounded),
                              label: Text(widget.strings.stopListening),
                            )
                          : FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _cortenColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                // Torna all'inizio prima di ripartire
                                if (_scrollController.hasClients) {
                                  _scrollController.jumpTo(0);
                                }
                                widget.ttsService
                                    .speak(displayText, languageCode: lang)
                                    .then((_) {
                                  final error = widget.ttsService.lastError;
                                  if (error != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error)),
                                    );
                                  }
                                });
                              },
                              icon: const Icon(Icons.volume_up_rounded),
                              label: Text(widget.strings.listen),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
