import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';

/// `IN100AutomationItems` — os itens **do XML** da NF-e.
///
/// É a espinha da lista de conferência: todo item que veio na nota está aqui,
/// tenha ou não consumo de pedido vinculado. Montar a lista a partir do consumo
/// de pedido faria sumir justamente os itens que ninguém conseguiu casar — e
/// item que some de uma contagem cega passa batido.
class In100AutomationItemDto {
  const In100AutomationItemDto({
    required this.chave,
    required this.accesskey,
    required this.item,
    required this.codigoProduto,
    required this.descricaoProduto,
    required this.unidadeComercial,
    required this.quantidadeComercial,
  });

  final String chave;
  final String accesskey;

  /// `Item` — CHAR(5) zero-padded (`'00010'`).
  final String item;

  /// `CProd` — código do material no XML do fornecedor.
  final String codigoProduto;

  /// `XProd` — descrição do produto no XML.
  final String descricaoProduto;

  /// `UCom` — unidade comercial do fornecedor (pode diferir da unidade SAP).
  final String unidadeComercial;

  /// `QCom` — quantidade comercial. Usada como esperada só quando o item não
  /// tem consumo de pedido.
  final double? quantidadeComercial;

  factory In100AutomationItemDto.fromJson(Map<String, dynamic> json) =>
      In100AutomationItemDto(
        chave: odataString(json['Chave']),
        accesskey: odataString(json['Accesskey']),
        item: odataString(json['Item']),
        codigoProduto: odataString(json['CProd']),
        descricaoProduto: odataString(json['XProd']),
        unidadeComercial: odataString(json['UCom']),
        quantidadeComercial: odataDecimal(json['QCom']),
      );
}
