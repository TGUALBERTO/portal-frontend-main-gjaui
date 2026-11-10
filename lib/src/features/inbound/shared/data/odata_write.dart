/// Serialização para o **corpo de escrita** do OData V2 (SAP Gateway).
///
/// Arquivo separado de `odata_json.dart` de propósito: aquele é leitura
/// *tolerante* (aceita `Edm.Decimal` como string ou número, `results` ou lista
/// crua). Escrita é o oposto — o Gateway exige um formato exato e responde 400
/// no coletor, na doca, quando erra por um caractere.
///
/// Nenhum destes formatos sai de um `jsonEncode` comum:
/// - data vira `/Date(milissegundos)/`
/// - hora vira duração ISO-8601 (`PT16H54M35S`)
/// - decimal viaja como **string**, com ponto
library;

/// `Edm.DateTime` do OData V2: `/Date(1786665600000)/`.
///
/// Usa os componentes de calendário **locais** de [momento] e os remonta como
/// meia-noite **UTC** — é assim que o Gateway serializa um campo DATS do ABAP.
///
/// Converter para UTC antes de truncar (`momento.toUtc()`) seria o erro fácil e
/// silencioso: no fuso -03:00, uma contagem às 21h viraria o dia seguinte, e o
/// `Credat` deixaria de bater com o [odataTime] do mesmo instante.
String odataDate(DateTime momento) {
  final dia = DateTime.utc(momento.year, momento.month, momento.day);
  return '/Date(${dia.millisecondsSinceEpoch})/';
}

/// `Edm.Time` do OData V2: `PT16H54M35S` — duração ISO-8601 desde a meia-noite.
///
/// Lê a hora de parede **local** de [momento], para casar com [odataDate].
/// Emite sempre os três componentes, com dois dígitos: é a forma que o próprio
/// serializador do SAP produz. `PT9H5M3S` também é `xs:duration` válido, mas
/// gravar no mesmo formato que o SAP evita surpresa em comparação de string do
/// lado ABAP.
String odataTime(DateTime momento) {
  String dois(int v) => v.toString().padLeft(2, '0');
  return 'PT${dois(momento.hour)}H${dois(momento.minute)}M'
      '${dois(momento.second)}S';
}

/// `Edm.Decimal` — o Gateway exige **string**, com ponto decimal.
///
/// [casas] default 4 porque é o que o `INCContagemACegaLog` usa (`"123.0000"`);
/// confira o `Scale` no `$metadata` antes de mudar.
///
/// `toStringAsFixed` e não `NumberFormat` do `intl`: o app roda em `pt_BR` e o
/// formatter produziria `123,0000`, que o SAP rejeita com 400.
String odataDecimalString(num valor, {int casas = 4}) =>
    valor.toStringAsFixed(casas);

/// NUMC zero-padded: `odataNumc(1, 3) == '001'`.
///
/// **Lança** [ArgumentError] quando o valor não cabe em [tamanho] ou é
/// negativo. Truncar em silêncio corromperia uma chave primária — e num log
/// append-only isso significa sobrescrever a tentativa de outra pessoa.
String odataNumc(int valor, int tamanho) {
  if (valor < 0) {
    throw ArgumentError.value(valor, 'valor', 'NUMC não aceita negativo');
  }
  final texto = valor.toString();
  if (texto.length > tamanho) {
    throw ArgumentError.value(
      valor,
      'valor',
      'Não cabe em NUMC($tamanho)',
    );
  }
  return texto.padLeft(tamanho, '0');
}
