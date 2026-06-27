# Ronda Stories

**Ronda Stories** è un'app mobile (Flutter/Dart) per tour geolocalizzati con storytelling audio.
Mentre cammini lungo un percorso, l'app riconosce automaticamente i punti di interesse
e racconta la loro storia con sintesi vocale multilingua.

---

## Il primo circuito: Ferraronda

> *4 passi tra le mura estensi*

Le mura estensi di Ferrara sono tra le più integre d'Europa: oltre 9 chilometri
di cinta muraria quasi intatti, dichiarati Patrimonio dell'Umanità UNESCO nel 1999.
Ferraronda guida il visitatore lungo l'intero perimetro con 18 punti di interesse,
testi in italiano, inglese e cinese, e narrazione vocale automatica.

---

## Caratteristiche principali

- **GPS reale** — la mappa segue la posizione dell'utente in tempo reale
- **Trigger automatico dei POI** — quando ti avvicini a un punto di interesse, il racconto parte da solo
- **Text-to-speech multilingua** — italiano, inglese, cinese (estendibile)
- **Tracking del percorso** — tempo, distanza, velocità media con pausa/riprendi
- **Traccia GPX reale** — il percorso mostrato sulla mappa è quello reale, non una spezzata
- **Architettura config-driven** — aggiungere un nuovo circuito richiede solo un file JSON, zero codice
- **Offline-first** — mappa e contenuti funzionano senza connessione (dopo il primo caricamento)

---

## Struttura del repository

```
RONDA-STORIES/
├── src/                        ← codice sorgente Flutter
│   ├── lib/
│   │   ├── models/             ← modelli dati (Circuit, Poi, TrackStats...)
│   │   ├── services/           ← logica (GPS, TTS, tracking, loader...)
│   │   └── screens/            ← UI (Home, Mappa, Lista POI, Settings)
│   ├── assets/
│   │   ├── circuits/
│   │   │   └── ferrara-classico/
│   │   │       ├── circuit.json   ← dati del circuito (POI, percorso, testi)
│   │   │       └── icon.png       ← icona del circuito
│   │   └── images/             ← logo e asset grafici dell'app
│   ├── android/                ← configurazione Android
│   ├── windows/                ← configurazione Windows (sviluppo/test)
│   └── pubspec.yaml
└── docs/                       ← documentazione
    ├── ARCHITETTURA.md
    ├── COME_AGGIUNGERE_RONDA.md
    └── CHANGELOG.md
```

---

## Come iniziare (sviluppatori)

### Prerequisiti

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.44
- Android Studio (per Android SDK e build Android)
- VS Code con estensione Flutter/Dart

### Setup

```bash
git clone https://github.com/stefanofranzoni-source/RONDA-STORIES.git
cd RONDA-STORIES/src
flutter pub get
flutter run -d windows    # test su desktop
flutter run -d <device>   # test su Android
```

### Dipendenze principali

| Pacchetto | Versione | Uso |
|---|---|---|
| `flutter_map` | 7.0.2 | Mappa OpenStreetMap |
| `geolocator` | 13.0.0 | GPS reale |
| `flutter_tts` | 4.0.2 | Text-to-speech |
| `latlong2` | 0.9.1 | Tipi geografici |

---

## Aggiungere un nuovo circuito

Vedi [`docs/COME_AGGIUNGERE_RONDA.md`](docs/COME_AGGIUNGERE_RONDA.md)

---

## Autore

**Stefano Franzoni**
Progetto: Ferraronda — valorizzazione turistica delle mura estensi di Ferrara

---

## Licenza

Tutti i diritti riservati © Stefano Franzoni
