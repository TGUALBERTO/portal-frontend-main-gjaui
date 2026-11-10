// Helpers de (de)serialização compartilhados pelos DTOs da feature TeamsBot
// (ATAs e reuniões).

/// Faz parse tolerante de data/hora ISO-8601 (com ou sem offset).
/// Retorna `null` para valores ausentes ou inválidos.
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final str = value.toString().trim();
  if (str.isEmpty) return null;
  return DateTime.tryParse(str);
}

/// Faz parse de uma data simples (`"2026-06-10"`). Aceita também ISO completo,
/// descartando o horário. Retorna `null` quando ausente/ inválida.
DateTime? parseDateOnly(dynamic value) {
  final parsed = parseDateTime(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Converte qualquer iterável JSON em `List<String>` não-nula.
List<String> parseStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}

/// Faz parse tolerante de um booleano (aceita bool ou string "true"/"false").
bool parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Faz parse de um inteiro, retornando `null` para valores ausentes.
int? parseIntOrNull(dynamic value) => (value as num?)?.toInt();
