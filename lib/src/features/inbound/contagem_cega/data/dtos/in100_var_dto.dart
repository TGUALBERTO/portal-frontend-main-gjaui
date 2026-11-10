import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';

/// `IN100Vars` — o fornecedor da NF-e.
///
/// `nomeFornecedor` é um campo que o time SAP ainda vai publicar; enquanto não
/// existir, o JSON simplesmente não o traz e o valor fica vazio — por isso a
/// chamada é feita **sem `$select`** (um `$select` com campo inexistente devolve
/// 400) e a nota cai no [lifnr] para exibição.
class In100VarDto {
  const In100VarDto({
    required this.chave,
    required this.accesskey,
    required this.lifnr,
    required this.nomeFornecedor,
  });

  final String chave;
  final String accesskey;

  /// Código do fornecedor no SAP.
  final String lifnr;

  /// Razão social. Vazia enquanto o campo não estiver publicado.
  final String nomeFornecedor;

  factory In100VarDto.fromJson(Map<String, dynamic> json) => In100VarDto(
        chave: odataString(json['Chave']),
        accesskey: odataString(json['Accesskey']),
        lifnr: odataString(json['Lifnr']),
        nomeFornecedor: odataString(json['NomeFornecedor']),
      );
}
