/// Contenuto testuale di un POI in UNA lingua specifica.
/// Il campo [altText] è opzionale: se presente, viene usato al posto
/// di [text] quando il POI scatta una seconda volta (es. al ritorno
/// al punto di partenza dopo aver visitato almeno un altro POI).
class PoiLocalizedContent {
  final String title;
  final String text;

  /// Testo alternativo opzionale — usato al ritorno al punto di partenza.
  /// Se null, viene usato [text] anche alla seconda lettura.
  final String? altText;

  const PoiLocalizedContent({
    required this.title,
    required this.text,
    this.altText,
  });

  factory PoiLocalizedContent.fromJson(Map<String, dynamic> json) {
    return PoiLocalizedContent(
      title: json['title'] as String,
      text: json['text'] as String,
      altText: json['alt_text'] as String?,
    );
  }
}
