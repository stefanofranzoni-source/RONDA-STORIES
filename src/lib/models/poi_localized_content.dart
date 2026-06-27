// In Dart non esistono header separati come in C/C++: dichiarazione e
// implementazione stanno nello stesso file. "class" funziona in modo simile
// a C++, ma tutto è già implicitamente "puntatore"/riferimento (non esiste
// il concetto di stack-allocation per gli oggetti come in C++).

/// Contenuto testuale di un POI in UNA lingua specifica.
/// Esempio: { "title": "Porta Po", "text": "..." }
class PoiLocalizedContent {
  final String title;
  final String text;

  const PoiLocalizedContent({
    required this.title,
    required this.text,
  });

  /// Costruttore "named" che costruisce l'oggetto a partire da una Map
  /// (cioè da quello che ottieni decodificando un pezzo di JSON).
  /// Questo pattern factory ricorre in tutti i modelli del progetto.
  factory PoiLocalizedContent.fromJson(Map<String, dynamic> json) {
    return PoiLocalizedContent(
      title: json['title'] as String,
      text: json['text'] as String,
    );
  }
}
