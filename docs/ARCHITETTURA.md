# Architettura di Ronda Stories

## Principio fondamentale: config-driven

Il codice Flutter non sa nulla di Ferrara, di Mantova, o di qualsiasi altra città.
Tutto ciò che è specifico di un circuito vive in un file JSON:

```
assets/circuits/<circuit_id>/circuit.json
```

L'app è un "player" generico che carica questo JSON e si comporta di conseguenza.
Per creare un nuovo circuito basta creare una nuova cartella con un nuovo JSON.

---

## Struttura del codice (`src/lib/`)

```
lib/
├── main.dart                        ← punto di ingresso, tema, TtsService globale
│
├── models/                          ← classi dati pure (niente logica UI)
│   ├── circuit.dart                 ← il circuito completo (POI, route, config)
│   ├── circuit_summary.dart         ← versione leggera per la Home (catalogo)
│   ├── poi.dart                     ← singolo punto di interesse
│   ├── poi_localized_content.dart   ← testo di un POI in una lingua
│   ├── start_point.dart             ← punto di partenza/arrivo (opzionale)
│   └── track_stats.dart             ← statistiche tracking (tempo/distanza/velocità)
│
├── services/                        ← logica di business, niente UI
│   ├── app_strings.dart             ← dizionario stringhe UI (IT/EN/ZH)
│   ├── circuit_loader.dart          ← carica Circuit da assets o URL
│   ├── geo_position_controller.dart ← GPS reale, permessi, trigger POI
│   ├── geo_utils.dart               ← calcolo distanza haversine
│   ├── language_controller.dart     ← lingua corrente (ChangeNotifier)
│   ├── track_recorder.dart          ← registra traccia, calcola statistiche
│   └── tts_service.dart             ← text-to-speech multilingua
│
└── screens/                         ← UI
    ├── home_screen.dart             ← catalogo circuiti / Home singolo circuito
    ├── map_screen.dart              ← mappa GPS con tracker e card POI
    ├── poi_list_screen.dart         ← lista POI (modalità "Esplora")
    ├── poi_detail_screen.dart       ← dettaglio singolo POI
    ├── settings_screen.dart         ← impostazioni app
    └── widgets/
        └── track_stats_panel.dart   ← pannello tempo/distanza/velocità
```

---

## Flusso principale (utente sul percorso)

```
App avviata
    └── HomeScreen carica CircuitSummary dal catalogo
            └── utente preme "Inizia percorso"
                    └── CircuitLoader.loadCircuit() → Circuit completo
                            └── MapScreen aperta con:
                                ├── GeoPositionController (GPS stream)
                                ├── TrackRecorder (statistiche)
                                └── TtsService (voce)
                                        │
                                        ▼
                                GPS aggiorna posizione
                                        │
                                GeoPositionController._checkPoiTriggers()
                                        │
                                    POI nel raggio?
                                    ├── No  → aggiorna marker utente sulla mappa
                                    └── Sì  → onPoiTriggered(poi)
                                                ├── setState(_activePoi = poi)
                                                ├── TtsService.speak(testo)
                                                └── [se auto] timer chiusura card
```

---

## Modello dati: Circuit

```dart
Circuit {
  circuitId: "ferrara-classico"
  name: "Ferraronda"
  icon: "icon.png"              // opzionale, fallback al logo app
  subtitle: Map<lang, testo>    // multilingua
  languages: ["it", "en", "zh"]
  themeColor: "#B7472A"         // Corten
  poiRetrigger: true
  poiPanelBehavior: auto|manual|ttsOnly|silent
  poiAutoCloseDelaySec: 4
  startPoint: StartPoint?       // opzionale
  route: List<{lat, lon}>       // 225 punti dal GPX semplificato
  poi: List<Poi>                // 18 punti di interesse ordinati
  version: "0.0.1"
  versionDate: "2026-06-25"
  author: "Stefano Franzoni"
}
```

---

## Gestione della lingua

La lingua è gestita a due livelli separati:

1. **Stringhe UI** (`app_strings.dart`) — pulsanti, etichette, messaggi
   dell'interfaccia, uguali per tutti i circuiti. Cambiano con la lingua
   selezionata dall'utente.

2. **Contenuti POI** (`circuit.json`) — testi narrativi specifici di ogni
   circuito, tradotti direttamente nel JSON.

Questo separa nettamente "cosa dice l'app" da "cosa racconta il circuito".

---

## GPS e trigger POI

Il `GeoPositionController` gestisce:
- Richiesta permessi di localizzazione a runtime (Android)
- Stream di posizioni GPS con `LocationAccuracy.best` e `distanceFilter: 3m`
- Calcolo distanza utente-POI con formula haversine (`GeoUtils`)
- Logica di trigger/ri-armo basata su `poiRetrigger` e `poi_panel_behavior`

Il `TrackRecorder` è completamente indipendente dal GPS: riceve punti
via `addPoint()` e calcola statistiche. Supporta pausa/riprendi con
accumulo corretto del tempo (`_elapsedBeforePause`).

---

## TTS (Text-to-Speech)

Il `TtsService` usa `flutter_tts` con:
- Selezione esplicita del motore Google (`com.google.android.tts`) per
  qualità vocale superiore (stesso motore di Google Maps)
- Rilevamento disponibilità lingua per ogni dispositivo (il formato
  restituito da `getLanguages()` varia tra produttori)
- Velocità configurabile dall'utente (slider nei Settings)
- Callback `onSpeakCompleted` per la chiusura automatica del pannello POI

---

## Aggiunta di piattaforme future

Il codice è già predisposto per:
- **Download circuiti da server**: `CircuitLoader` ha un metodo
  `loadFromUrl()` pronto, basta implementarlo
- **Audio pre-registrato**: il modello `PoiLocalizedContent` ha un campo
  `audio` predisposto per file `.mp3`
- **Altitudine/dislivello**: `TrackPoint` e `Poi` hanno già il campo `alt`
- **Pre-racconto** (inizia a parlare 100m prima del POI): architettura
  predisposta, non ancora implementato
