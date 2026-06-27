import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/circuit.dart';
import '../models/circuit_summary.dart';

/// Catalogo statico dei circuiti disponibili nell'app.
/// Per aggiungere un nuovo circuito: crea la cartella in
/// assets/circuits/<circuit_id>/ con circuit.json e icon.png,
/// poi aggiungi l'ID qui e in pubspec.yaml.
const _availableCircuitIds = [
  'ferrara-classico',
  // 'mantova-classico',  ← esempio future Ronde
];

class CircuitLoader {
  /// Carica la lista dei circuiti disponibili per la Home (catalogo).
  /// Carica solo i metadati essenziali per le card, non l'intero circuito.
  static Future<List<CircuitSummary>> loadCatalog() async {
    final summaries = <CircuitSummary>[];
    for (final id in _availableCircuitIds) {
      try {
        final circuit = await loadCircuit(id);
        summaries.add(CircuitSummary(
          circuitId: circuit.circuitId,
          name: circuit.name,
          subtitle: circuit.subtitle,
          themeColor: circuit.themeColor,
          icon: circuit.icon,
        ));
      } catch (e) {
        // Se un circuito non si carica (es. file mancante), lo saltiamo
        // senza bloccare il resto del catalogo.
      }
    }
    return summaries;
  }

  /// Carica il circuito completo dalla cartella assets/circuits/<circuitId>/
  static Future<Circuit> loadCircuit(String circuitId) async {
    final path = 'assets/circuits/$circuitId/circuit.json';
    final jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> jsonMap =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return Circuit.fromJson(jsonMap);
  }
}
