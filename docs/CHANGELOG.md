# Changelog — Ronda Stories

Tutte le modifiche significative al progetto sono documentate qui.
Il formato segue [Keep a Changelog](https://keepachangelog.com/it/1.0.0/).

---

## [0.1.0] — 2026-06-27 — Prima versione funzionante

### Aggiunto
- **App Flutter** con supporto Windows (sviluppo/test) e Android
- **Home Screen** con logo Ferraronda prominente, pulsanti "Inizia percorso"
  ed "Esplora", selettore lingua IT/EN/ZH, accesso Settings
- **Mappa GPS** basata su OpenStreetMap (flutter_map) con:
  - Traccia GPX reale delle mura estensi (225 punti, 9.55 km)
  - Marker personalizzati per POI (pin numerato Corten, bandierina per
    partenza/arrivo, grigio per POI già visitati)
  - Follow automatico della posizione utente (stile navigatore)
  - Pulsante ricentratura (appare solo quando il follow è disattivato)
  - Preview POI toccando il marker (senza segnarlo come visitato)
- **Tracking percorso**: tempo, distanza percorsa, velocità media
  con pausa/riprendi e reset via doppio tap
- **Trigger automatico POI**: quando l'utente entra nel raggio di un
  punto di interesse, appare la card informativa e parte la lettura vocale
- **Card POI**: intestazione Corten con numero e titolo, testo scorrevole,
  pulsante Ascolta/Interrompi, animazione slide-up, modalità preview
- **Text-to-speech** multilingua con motore Google TTS, velocità
  configurabile, rilevamento disponibilità lingua per dispositivo
- **`poi_panel_behavior`**: auto (chiusura dopo TTS), manual, tts_only, silent
- **18 POI** del circuito Ferraronda con testi in IT/EN/ZH:
  1. Baluardo di San Paolo
  2. Porta Paola
  3. Baluardo di San Lorenzo
  4. Baluardo e Porta di San Pietro
  5. Baluardo di Sant'Antonio
  6. Le Mura Nuove di Borso d'Este
  7. Porta Romana o di San Giorgio
  8. Barbacane o Baluardo di San Giorgio
  9. Baluardo della Montagna
  10. Ex Baluardo di San Rocco
  11. Le Mura di Ercole I d'Este, Torrione San Giovanni
  12. Montagnola del Barchetto o Rotonda
  13. Porta degli Angeli
  14. Le Mura
  15. Torrione del Barco
  16. Isola e Palazzo di Belvedere
  17. Darsena
  18. Partenza / Arrivo
- **Schermata Esplora**: lista POI navigabile con dettaglio e TTS
- **Settings**: lingua, velocità voce, versione circuito, Esci
- **Architettura config-driven**: ogni circuito è un JSON + PNG,
  zero codice Dart da toccare per aggiungere una nuova Ronda
- **Struttura catalogo**: predisposta per più circuiti (Mantovaronda, ecc.)

### Tecnico
- Flutter 3.44.1 / Dart 3.12.1
- Dipendenze: flutter_map 7.0.2, geolocator 13.0.0, flutter_tts 4.0.2, latlong2 0.9.1
- Algoritmo Ramer-Douglas-Peucker per semplificazione GPX (5385 → 225 punti)
- Formula haversine per calcolo distanze GPS
- Timer indipendente per cronometro (non dipende da aggiornamenti GPS)
- Supporto pause/resume con accumulo corretto del tempo trascorso

---

## Roadmap

### Da fare
- [ ] GPS reale: sostituire simulatore con geolocator (parzialmente fatto)
- [ ] `poi_panel_behavior: auto` con chiusura automatica post-TTS
- [ ] Pre-racconto 100m prima del POI successivo (opzionale)
- [ ] Audio pre-registrato per i POI principali
- [ ] Download circuiti da server (vs bundle nell'app)
- [ ] Testi definitivi dai totem reali (attualmente placeholder informativi)
- [ ] Pubblicazione Play Store

### Idee future
- Vibrazione/haptic feedback al trigger POI
- Modalità "notte" (mappa scura)
- Statistiche sessione al termine del percorso
- Condivisione traccia percorsa
- Supporto percorsi lineari (non solo circolari)
