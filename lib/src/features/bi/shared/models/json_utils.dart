// Helpers de parse tolerante para os DTOs do BI (respostas do backend `core`).

/// Converte para double; nulos/ausentes viram 0.
double parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// Converte para int; nulos/ausentes viram 0.
int parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

/// Converte para String não-nula.
String parseStr(dynamic v) => v?.toString() ?? '';

/// Lista JSON → `List<T>` mapeada; nulo vira lista vazia.
List<T> parseList<T>(dynamic v, T Function(Map<String, dynamic>) from) {
  if (v is List) {
    return v
        .whereType<Map<String, dynamic>>()
        .map(from)
        .toList(growable: false);
  }
  return const [];
}
