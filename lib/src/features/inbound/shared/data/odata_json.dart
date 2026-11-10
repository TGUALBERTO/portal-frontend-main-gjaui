/// Leitura tolerante do JSON do OData V2.
///
/// O Gateway tem duas manias que quebram parsing ingênuo:
/// - `Edm.Decimal` é serializado como **string** (`"2.000"`), enquanto
///   `Edm.Int32` vem como número. Um `as num` estoura no primeiro caso.
/// - campos ausentes viram `null` em vez de não existir, e campos CHAR vêm com
///   espaços de preenchimento do ABAP.
library;

/// String limpa, ou `''` quando ausente/nula.
String odataString(dynamic value) => value?.toString().trim() ?? '';

/// `Edm.Decimal` (string) ou `Edm.Int32`/`Edm.Double` (número) como [double].
///
/// Devolve `null` quando o valor não existe ou não é numérico — o chamador
/// decide se isso é erro ou zero, porque as duas leituras aparecem: quantidade
/// ausente num item é dado faltando, mas num total é zero.
double? odataDecimal(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final texto = value.toString().trim();
  if (texto.isEmpty) return null;
  return double.tryParse(texto);
}

/// Chave de junção para campo **NUMC**, sem os zeros à esquerda.
///
/// O Gateway não é consistente em como serializa NUMC: o mesmo item de pedido
/// sai `'00010'` de um entity set e `'10'` de outro (já visto em QAS, com
/// `IN100AutomationItems.Item` voltando `'1'`). Cruzar os dois lados pelo valor
/// cru faz o `Map` errar silenciosamente — e um cruzamento que erra em silêncio
/// não vira erro na tela, vira **campo vazio ou repetido**, que é muito mais
/// difícil de perceber.
///
/// Use só para **chave de mapa em memória**. O valor mandado ao SAP (`$filter`,
/// key predicate, corpo de POST) tem que ser o literal que ele devolveu.
String odataNumcKey(String value) {
  final semZeros = value.trim().replaceFirst(RegExp(r'^0+'), '');
  return semZeros.isEmpty ? '0' : semZeros;
}

/// Lista de objetos de uma navegação expandida.
///
/// O `$expand` do Gateway devolve `{"results": [...]}`, mas algumas versões
/// devolvem a lista crua — as duas formas aparecem no mesmo serviço dependendo
/// da cardinalidade, então vale aceitar ambas.
List<Map<String, dynamic>> odataChildren(dynamic value) {
  if (value is Map) {
    final results = value['results'];
    if (results is List) {
      return results.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const [];
  }
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  return const [];
}
