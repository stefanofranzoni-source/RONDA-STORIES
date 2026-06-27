/// Rappresenta una voce del catalogo dei circuiti disponibili nell'app.
/// Contiene solo i dati necessari per mostrare la card nella Home —
/// non carica l'intero Circuit (con tutti i POI) finché l'utente
/// non seleziona un circuito specifico.
class CircuitSummary {
  /// ID del circuito, corrisponde al nome della cartella in assets/circuits/
  final String circuitId;

  /// Nome visualizzato nella card (es. "Ferraronda")
  final String name;

  /// Sottotitolo multilingua
  final Map<String, String> subtitle;

  /// Colore tema del circuito (hex "#RRGGBB")
  final String themeColor;

  /// Nome del file icona (opzionale, nella cartella del circuito)
  final String? icon;

  const CircuitSummary({
    required this.circuitId,
    required this.name,
    required this.subtitle,
    required this.themeColor,
    this.icon,
  });

  String subtitleFor(String languageCode) {
    return subtitle[languageCode] ?? subtitle['it'] ?? '';
  }

  int get themeColorValue {
    final hex = themeColor.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }

  /// Percorso dell'asset icona del circuito, se presente.
  String? iconAssetPath() {
    if (icon == null) return null;
    return 'assets/circuits/$circuitId/$icon';
  }
}
