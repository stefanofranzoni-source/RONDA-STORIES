# Ferraronda — Prototipo App (Fase 1)

Prototipo dell'app per il circuito Ferraronda: struttura dati + UI base con
selezione lingua e lista/dettaglio dei punti di interesse (POI).

Nessun GPS reale in questa fase: i contenuti vengono mostrati semplicemente
scorrendo la lista.

## Struttura del progetto

```
ferraronda/
├── assets/
│   └── circuits/
│       └── ferraronda.json     ← dati del circuito (POI, lingue, testi)
├── lib/
│   ├── models/                 ← classi dati (Circuit, Poi, ecc.)
│   ├── services/                ← caricamento JSON, gestione lingua
│   ├── screens/                 ← schermate UI
│   └── main.dart                ← punto di ingresso
└── pubspec.yaml                 ← dipendenze e dichiarazione asset
```

## Come avviare il progetto la prima volta

Questi file (`lib/`, `assets/`, `pubspec.yaml`) NON sono ancora un progetto
Flutter completo: mancano le cartelle generate automaticamente per ogni
piattaforma (`android/`, `ios/`, `windows/`, `web/`...). Vanno generate UNA
SOLA VOLTA con il comando `flutter create`, dentro la cartella del progetto.

Passi:

1. Apri il terminale di VS Code nella cartella che CONTIENE `ferraronda/`
   (cioè la cartella padre, non quella già dentro).

2. Se hai scaricato/copiato questi file in una cartella che già si chiama
   `ferraronda`, entra in quella cartella e lancia:

   ```
   flutter create .
   ```

   Il punto finale è importante: dice a Flutter "genera il progetto QUI",
   senza creare una sotto-cartella. Questo comando aggiungerà le cartelle
   `android/`, `ios/`, `windows/`, `web/`, ecc. SENZA toccare i file che
   abbiamo già scritto in `lib/` e `assets/` (potrebbe sovrascrivere
   `pubspec.yaml`: se succede, recupera la versione di questo prototipo
   e reincolla la sezione `dependencies` e `flutter: assets:`).

3. Scarica le dipendenze dichiarate in `pubspec.yaml`:

   ```
   flutter pub get
   ```

4. Avvia l'app. Per il prototipo, la via più rapida (senza emulatori
   Android/iOS) è eseguirla come app Windows desktop o nel browser:

   ```
   flutter run -d windows
   ```

   oppure

   ```
   flutter run -d chrome
   ```

   Per vedere quali "device" sono disponibili sul tuo PC:

   ```
   flutter devices
   ```

## Cosa fa questo prototipo

- Carica `assets/circuits/ferraronda.json` all'avvio.
- Mostra titolo e sottotitolo del circuito.
- Mostra la lista dei POI (Porta degli Angeli, Porta Po) con un'anteprima
  del testo.
- Permette di cambiare lingua (IT/EN) da un menu in alto a destra: tutti i
  testi si aggiornano immediatamente.
- Toccando un POI si apre la schermata di dettaglio col testo completo.

## Come aggiungere un nuovo POI

Basta aggiungere un nuovo oggetto nell'array `"poi"` dentro
`assets/circuits/ferraronda.json`, seguendo la stessa struttura degli
esempi esistenti (id, order, lat, lon, trigger_radius_m, content per
ogni lingua). Non serve toccare nessun file `.dart`.

## Come creare in futuro un nuovo circuito (es. Mantovaronda)

1. Duplica `assets/circuits/ferraronda.json` come
   `assets/circuits/mantovaronda.json` e modifica i contenuti.
2. Aggiungi il nuovo file nella sezione `flutter: assets:` di
   `pubspec.yaml`.
3. In `lib/main.dart`, cambia `circuitId: 'ferraronda'` in
   `circuitId: 'mantovaronda'` (oppure, più avanti, rendi questo
   parametro selezionabile a runtime da un menu iniziale).

## Prossime fasi (non ancora implementate)

- **Fase 2**: mappa del percorso con posizione utente simulata, trigger
  dei POI basato sulla vicinanza.
- **Fase 3**: GPS reale (pacchetto `geolocator`) + tracking di
  tempo/distanza/velocità media durante la camminata.
- **Fase 4**: lettura vocale dei testi (text-to-speech, pacchetto
  `flutter_tts`).
