import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';

/// `IN100XmlItemsConsumByItemPO` — o casamento XML × pedido (a CDS "XMLvsPedido").
///
/// A chave tem **seis** campos porque um item do XML pode ser consumido por mais
/// de um item de pedido. A unidade de contagem, porém, é
/// `(Chave, Accesskey, Item, nLote)`: a quantidade esperada é a **soma** de
/// [quantidade] dentro desse grupo.
class In100XmlItemConsumoDto {
  const In100XmlItemConsumoDto({
    required this.chave,
    required this.accesskey,
    required this.item,
    required this.lote,
    required this.pedido,
    required this.itemPedido,
    required this.quantidade,
    required this.unidade,
  });

  final String chave;
  final String accesskey;

  /// `Item` — CHAR(5) zero-padded.
  final String item;

  /// `nLote` — key NOT NULL no SAP: material sem lote chega como `''`.
  final String lote;

  /// `Ebeln` — documento de compras.
  final String pedido;

  /// `Ebelp` — item do documento de compras, CHAR(5) zero-padded.
  final String itemPedido;

  /// `Menge` — `Edm.Decimal(13,3)`, chega como string.
  final double? quantidade;

  /// `Meins` — unidade de medida do pedido.
  final String unidade;

  factory In100XmlItemConsumoDto.fromJson(Map<String, dynamic> json) =>
      In100XmlItemConsumoDto(
        chave: odataString(json['Chave']),
        accesskey: odataString(json['Accesskey']),
        item: odataString(json['Item']),
        lote: odataString(json['nLote']),
        pedido: odataString(json['Ebeln']),
        itemPedido: odataString(json['Ebelp']),
        quantidade: odataDecimal(json['Menge']),
        unidade: odataString(json['Meins']),
      );

  /// Par `(Ebeln, Ebelp)` para cruzar com `IN100POs`.
  ///
  /// Normalizado por [odataNumcKey] — ver `In100PoDto.chave`.
  (String, String) get chavePedido => (pedido, odataNumcKey(itemPedido));

  /// `'4501548574 / 10'` — como o conferente lê no papel.
  String get pedidoLabel {
    final itemSemZeros = itemPedido.replaceFirst(RegExp(r'^0+'), '');
    return '$pedido / ${itemSemZeros.isEmpty ? itemPedido : itemSemZeros}';
  }
}
