# Come aggiungere un nuovo circuito (Ronda)

Questa guida spiega come creare un nuovo circuito — ad esempio
**Mantovaronda**, **Pisaronda**, o **BerlinRonda** — senza toccare
nessun file Dart.

---

## 1. Crea la cartella del circuito

```
src/assets/circuits/<circuit_id>/
```

Esempio: `src/assets/circuits/mantova-classico/`

Il `circuit_id` deve essere in minuscolo con trattini, senza spazi.

---

## 2. Prepara l'icona (opzionale)

Metti un file `icon.png` nella cartella del circuito.
Dimensione consigliata: almeno 512×512 pixel, formato circolare
o quadrato (l'app lo ritaglia in cerchio automaticamente).

Se non metti nessuna icona, l'app usa quella di default di Ronda Stories.

---

## 3. Crea il file `circuit.json`

Copia e adatta questo template:

```json
{
  "circuit_id": "mantova-classico",
  "name": "Mantovaronda",
  "icon": "icon.png",
  "subtitle": {
    "it": "Un giro tra i Gonzaga",
    "en": "A walk through the Gonzaga",
    "zh": "贡扎加家族漫步之旅"
  },
  "languages": ["it", "en", "zh"],
  "default_language": "it",
  "theme_color": "#2E6B3E",
  "poi_retrigger": true,
  "poi_panel_behavior": "auto",
  "poi_auto_close_delay_s": 4,
  "version": "0.0.1",
  "version_date": "2026-06-25",
  "author": "Nome Autore",
  "route": [
    {"lat": 45.1564, "lon": 10.7914},
    {"lat": 45.1570, "lon": 10.7920}
  ],
  "poi": [
    {
      "id": "palazzo_te",
      "order": 1,
      "lat": 45.1480,
      "lon": 10.7960,
      "trigger_radius_m": 40,
      "content": {
        "it": {
          "title": "Palazzo Te",
          "text": "Palazzo Te fu costruito da Giulio Romano per Federico II Gonzaga..."
        },
        "en": {
          "title": "Palazzo Te",
          "text": "Palazzo Te was built by Giulio Romano for Federico II Gonzaga..."
        },
        "zh": {
          "title": "德宫",
          "text": "德宫由朱利奥·罗马诺为费德里科二世·贡扎加建造..."
        }
      }
    }
  ]
}
```

### Campi obbligatori

| Campo | Descrizione |
|---|---|
| `circuit_id` | ID univoco, stesso nome della cartella |
| `name` | Nome visualizzato nell'app |
| `subtitle` | Sottotitolo multilingua |
| `languages` | Lingue supportate (devono avere testo in tutti i POI) |
| `default_language` | Lingua di fallback se quella selezionata non è disponibile |
| `theme_color` | Colore principale in formato `#RRGGBB` |
| `poi` | Lista dei punti di interesse (almeno 1) |

### Campi opzionali

| Campo | Default | Descrizione |
|---|---|---|
| `icon` | logo app | Nome file icona nella cartella del circuito |
| `poi_retrigger` | `true` | Se `false`, ogni POI scatta una sola volta |
| `poi_panel_behavior` | `"manual"` | `auto`, `manual`, `tts_only`, `silent` |
| `poi_auto_close_delay_s` | `4` | Secondi prima della chiusura automatica (solo con `auto`) |
| `route` | [] | Array di punti lat/lon per la traccia sulla mappa |
| `start_point` | null | Punto di partenza fisso (opzionale) |
| `version` | `"0.0.1"` | Versione del circuito |
| `version_date` | `""` | Data dell'ultima modifica |
| `author` | `""` | Autore/curatore dei contenuti |

---

## 4. Come ottenere le coordinate dei POI

**Metodo consigliato — GPS Status sul campo:**
1. Installa [GPS Status & Toolbox](https://play.google.com/store/apps/details?id=com.eclipsim.gpsstatus2) su Android
2. Vai fisicamente davanti al punto di interesse
3. Aspetta 15-20 secondi che il GPS si stabilizzi (accuratezza ≤ 5m)
4. Leggi lat/lon a 6 decimali e trascrivili nel JSON

**Metodo alternativo — Google Maps:**
- Tieni premuto su un punto della mappa → compare lat/lon in basso
- Meno preciso per punti fisici specifici, ottimo per punti identificabili sulla mappa

**`trigger_radius_m` consigliato:**
- All'aperto con buon segnale GPS: `15-20` metri
- Se il POI è a qualche metro dal percorso: `30-40` metri
- In centro storico con edifici alti: `40-50` metri

---

## 5. Come preparare la traccia GPX

Se hai un file GPX del percorso (registrato con app di tracking come
Strava, Komoot, OsmAnd):

1. Carica il file GPX come allegato in una conversazione con Claude
2. Chiedi di semplificarlo e convertirlo nel formato `route` del JSON
3. Il file risultante avrà ~200-300 punti invece di migliaia,
   per un peso di ~10-15 KB invece di centinaia di KB

Se non hai un GPX, puoi omettere il campo `route`: l'app mostrerà
una linea spezzata che collega i POI in ordine, meno precisa ma funzionale.

---

## 6. Registra il circuito nell'app

Apri `src/lib/services/circuit_loader.dart` e aggiungi il nuovo ID:

```dart
const _availableCircuitIds = [
  'ferrara-classico',
  'mantova-classico',   // ← aggiungi qui
];
```

---

## 7. Dichiara gli asset in pubspec.yaml

Apri `src/pubspec.yaml` e aggiungi la nuova cartella:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/circuits/ferrara-classico/
    - assets/circuits/mantova-classico/    # ← aggiungi qui
```

---

## 8. Testa il circuito

```bash
cd src
flutter run -d windows    # test rapido su desktop (senza GPS reale)
flutter run -d <device>   # test completo su Android con GPS
```

---

## Note sui testi

- I testi vengono letti ad alta voce dal motore TTS — scrivi frasi
  complete e naturali, come le leggerebbe una guida turistica
- Evita abbreviazioni (es. scrivi "secolo" non "sec.", "metri" non "m")
- Per l'italiano, puoi usare accenti grafici per guidare la pronuncia
  (es. "erbòsi" invece di "erbosi") — alcuni motori TTS li rispettano
- Lunghezza consigliata per testo TTS: 3-6 frasi (30-60 secondi di lettura)
- Il testo può essere più lungo per la modalità "Esplora" (lettura visiva)
- Il cinese viene tradotto da Claude se fornisci il testo in italiano
