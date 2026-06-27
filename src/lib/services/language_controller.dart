import 'package:flutter/foundation.dart';

/// Tiene traccia della lingua attualmente selezionata nell'app e notifica
/// tutti i widget interessati quando cambia.
///
/// "ChangeNotifier" è una classe base di Flutter pensata esattamente per
/// questo: un oggetto "osservabile" a cui i widget si iscrivono, un po'
/// come un Subject in un pattern Observer che probabilmente già conosci
/// da C++. Quando chiamiamo notifyListeners(), tutti i widget in ascolto
/// si ridisegnano automaticamente.
class LanguageController extends ChangeNotifier {
  String _currentLanguage;

  LanguageController(String initialLanguage) : _currentLanguage = initialLanguage;

  String get currentLanguage => _currentLanguage;

  void setLanguage(String languageCode) {
    if (languageCode == _currentLanguage) return;
    _currentLanguage = languageCode;
    notifyListeners();
  }
}
