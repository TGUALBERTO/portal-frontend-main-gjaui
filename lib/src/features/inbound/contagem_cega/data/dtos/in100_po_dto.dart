import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';

/// `IN100POs` — o item do pedido de compras.
///
/// É a única fonte do **material do SAP** e da sua descrição: nem
/// `IN100AutomationItems` (que traz o material do fornecedor) nem
/// `IN100XmlItemsConsumByItemPO` (que traz só a referência ao pedido) têm isso.
///
/// `DescricaoMaterial` é o **`MAKTX` do cadastro de material**, e a CDS o resolve
/// por `spras = $session.system_language`. Se ele vier vazio com `Material`
/// preenchido, o material existe mas não tem texto no idioma da sessão do
/// usuário de serviço — o problema está no cadastro/idioma, não no cruzamento.
class In100PoDto {
  const In100PoDto({
    required this.pedido,
    required this.item,
    required this.material,
    required this.descricaoMaterial,
    required this.unidade,
  });

  /// `PedidoCompra` — casa com `Ebeln`.
  final String pedido;

  /// `Item` — casa com `Ebelp`.
  final String item;

  final String material;
  final String descricaoMaterial;
  final String unidade;

  factory In100PoDto.fromJson(Map<String, dynamic> json) => In100PoDto(
        pedido: odataString(json['PedidoCompra']),
        item: odataString(json['Item']),
        material: odataString(json['Material']),
        descricaoMaterial: odataString(json['DescricaoMaterial']),
        unidade: odataString(json['UnidadeMedida']),
      );

  /// Par `(PedidoCompra, Item)` para cruzar com `IN100XmlItemsConsumByItemPO`.
  ///
  /// O item passa por [odataNumcKey]: `Ebelp` e `Item` são o mesmo NUMC(5), mas
  /// os dois entity sets não o serializam do mesmo jeito, e um cruzamento que
  /// erra deixa a tela sem o nome do material do SAP.
  (String, String) get chave => (pedido, odataNumcKey(item));
}
