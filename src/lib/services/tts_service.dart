import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Stato della lettura vocale in corso, utile alla UI per decidere cosa
/// mostrare (es. icona "play" oppure "stop" sul pulsante Ascolta).
enum TtsStatus { idle, speaking }

/// Incapsula flutter_tts dietro un'interfaccia semplice, pensata per
/// essere usata da qualunque schermata (dettaglio POI, card sulla mappa,
/// ecc.) senza che quelle schermate debbano conoscere i dettagli del
/// pacchetto sottostante. Se domani cambiassimo motore TTS (es. per usare
/// voci professionali pre-registrate), basterebbe riscrivere questa
/// classe, non i widget che la usano.
class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  TtsStatus _status = TtsStatus.idle;
  TtsStatus get status => _status;

  bool get isSpeaking => _status == TtsStatus.speaking;

  String? _lastError;
  String? get lastError => _lastError;

  /// Velocità di lettura corrente (0.25 = lenta, 0.45 = default, 0.9 = veloce).
  /// Modificabile dall'utente tramite lo slider nei Settings.
  double _speechRate = 0.45;
  double get speechRate => _speechRate;

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.25, 0.9);
    notifyListeners();
  }
  /// (non quando viene interrotta manualmente con stop()). La MapScreen
  /// la usa per avviare il timer di chiusura automatica del pannello POI
  /// quando poi_panel_behavior è "auto".
  void Function()? onSpeakCompleted;

  TtsService() {
    _flutterTts.setCompletionHandler(() {
      _status = TtsStatus.idle;
      notifyListeners();
      onSpeakCompleted?.call();
    });
    _flutterTts.setCancelHandler(() {
      _status = TtsStatus.idle;
      notifyListeners();
    });
    _flutterTts.setErrorHandler((message) {
      _status = TtsStatus.idle;
      _lastError = message?.toString();
      notifyListeners();
    });

    // Inizializziamo il motore in modo asincrono subito dopo la
    // costruzione: proviamo a selezionare il motore Google TTS
    // (lo stesso usato da Google Maps/navigatore), che offre voci
    // neurali più naturali rispetto al motore di default del produttore
    // (es. quello Samsung). Se non è installato sul dispositivo,
    // ricadiamo silenziosamente sul motore di default.
    _initEngine();
  }

  Future<void> _initEngine() async {
    const googleEngine = 'com.google.android.tts';
    try {
      final dynamic engines = await _flutterTts.getEngines;
      if (engines is List) {
        final engineList = engines.map((e) => e.toString()).toList();
        debugPrint('[TTS] Motori disponibili: $engineList');
        if (engineList.contains(googleEngine)) {
          await _flutterTts.setEngine(googleEngine);
          debugPrint('[TTS] Motore Google TTS selezionato');
        } else {
          debugPrint('[TTS] Motore Google non trovato, uso il default');
        }
      }
    } catch (e) {
      // Su Windows o in ambienti dove getEngines non è supportato,
      // ignoriamo silenziosamente l'errore.
      debugPrint('[TTS] getEngines non supportato su questa piattaforma: $e');
    }
  }

  /// Converte il nostro codice lingua interno ("it", "en", ...) nel
  /// codice locale richiesto dai motori TTS dei vari sistemi operativi
  /// ("it-IT", "en-US", ...). Se in futuro aggiungerai altre lingue ai
  /// circuiti, aggiungi qui la mappatura corrispondente.
  String _localeFor(String languageCode) {
    switch (languageCode) {
      case 'it':
        return 'it-IT';
      case 'en':
        return 'en-US';
      case 'de':
        return 'de-DE';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'zh':
        return 'zh-CN';
      default:
        return 'en-US';
    }
  }

  /// Verifica se la lingua richiesta è effettivamente disponibile come
  /// voce sul dispositivo corrente. Su Windows dipende dalle voci
  /// installate nel sistema operativo; su Android/iOS dipende dai
  /// pacchetti voce del motore TTS di sistema. Utile per dare un
  /// messaggio chiaro invece di un silenzio inspiegabile.
  Future<bool> isLanguageAvailable(String languageCode) async {
    final dynamic rawLanguages = await _flutterTts.getLanguages;

    if (rawLanguages is! List) {
      debugPrint('[TTS] getLanguages non ha restituito una lista: $rawLanguages');
      return false;
    }

    final availableLocales = rawLanguages.map((e) => e.toString()).toList();

    debugPrint('[TTS] Cerco lingua: $languageCode');
    debugPrint('[TTS] Lingue disponibili sul dispositivo: $availableLocales');

    final found = availableLocales.any((locale) => _localeMatches(locale, languageCode));

    debugPrint('[TTS] Lingua "$languageCode" trovata: $found');
    return found;
  }

  /// Confronta una stringa locale restituita dal motore TTS del
  /// dispositivo (es. "it-IT", "ita-default", "it_IT", "ita-x-lvariant-f00")
  /// con il nostro codice lingua a 2 lettere (es. "it").
  ///
  /// Diversi produttori/motori TTS usano formati diversi per identificare
  /// le lingue: alcuni seguono lo standard "it-IT" (ISO 639-1 + paese),
  /// altri (es. alcuni dispositivi Samsung) usano un formato a 3 lettere
  /// stile ISO 639-2 con suffissi proprietari ("ita-default"). Pretendere
  /// una corrispondenza esatta col formato standard fallisce su questi
  /// dispositivi anche quando la lingua è realmente disponibile.
  ///
  /// La soluzione robusta: invece di confrontare l'intera stringa,
  /// guardiamo solo se il locale disponibile CONTIENE il prefisso a 2
  /// lettere del codice lingua come parola a sé (delimitata da inizio
  /// stringa, '-' o '_'), così riconosciamo sia "it-IT" sia "ita-default"
  /// sia "it_IT" come corrispondenti a "it".
  bool _localeMatches(String availableLocale, String languageCode) {
    final normalized = availableLocale.toLowerCase().replaceAll('_', '-');
    final prefix = languageCode.toLowerCase();

    // Confronto sul primo "segmento" del locale (prima del primo '-'),
    // troncato alla lunghezza del nostro codice lingua. Copre sia "it"
    // (segmento "it") sia "ita-default" (segmento "ita", i cui primi 2
    // caratteri sono "it").
    final firstSegment = normalized.split('-').first;
    return firstSegment.startsWith(prefix);
  }

  /// Legge ad alta voce il testo fornito, nella lingua specificata.
  /// Se una lettura precedente è in corso, viene interrotta prima di
  /// iniziarne una nuova. Se la lingua richiesta non risulta disponibile
  /// sul dispositivo, imposta lastError invece di tentare comunque una
  /// lettura che il motore TTS potrebbe ignorare silenziosamente.
  Future<void> speak(String text, {required String languageCode}) async {
    if (_status == TtsStatus.speaking) {
      await stop();
    }

    _lastError = null;

    final available = await isLanguageAvailable(languageCode);
    if (!available) {
      _lastError =
          'Voce "${_localeFor(languageCode)}" non disponibile su questo dispositivo.';
      notifyListeners();
      return;
    }

    await _flutterTts.setLanguage(_localeFor(languageCode));
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _status = TtsStatus.speaking;
    notifyListeners();

    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _status = TtsStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
