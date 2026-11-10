import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_quantidade.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';

/// Um item da NF-e a ser conferido.
///
/// Carrega os dois lados da conferência: o que veio no **XML da nota**
/// (`materialXml`, `descricaoXml`, `quantidadeNf`, `loteNf`) e o que o **SAP**
/// conhece (`materialSap`, `descricaoSap`) — os códigos de material raramente
/// coincidem, e é o par que permite o conferente confirmar que está contando a
/// peça certa.
///
/// O mesmo `itemXml` pode aparecer mais de uma vez quando a NF traz vários
/// lotes do mesmo material — cada lote é uma contagem separada.
class ContagemItem extends Equatable {
  const ContagemItem({
    required this.itemXml,
    required this.loteNf,
    required this.pedidos,
    required this.quantidadeNf,
    required this.unidade,
    required this.materialSap,
    required this.descricaoSap,
    required this.materialXml,
    required this.descricaoXml,
    this.semPedido = false,
    this.status = ContagemItemStatus.pendente,
    this.tentativas = 0,
    this.quantidadeContada,
    this.loteLido = '',
  });

  /// Número do item dentro do XML da NF-e, **como o SAP devolve**: CHAR(5) com
  /// zeros à esquerda (`'00010'`).
  ///
  /// String e não `int` porque o valor zero-padded é o literal exigido no
  /// `$filter` e na key predicate — converter para `int` e reconstruir depois é
  /// como se perde um item numa consulta.
  final String itemXml;

  /// Lote informado na nota. Vazio quando o material não é controlado por lote.
  final String loteNf;

  /// Itens de pedido que este `(item, lote)` consome, já formatados
  /// (`'4501548574 / 00010'`).
  ///
  /// É lista porque o agrupamento da contagem é por `(Chave, Accesskey, Item,
  /// nLote)` e um mesmo lote pode ser consumido por mais de um item de pedido —
  /// com um campo escalar seria preciso escolher um e omitir os outros.
  final List<String> pedidos;

  /// Item do XML sem nenhum consumo de pedido vinculado.
  ///
  /// Ele **entra** na conferência assim mesmo: a carga chegou fisicamente e
  /// precisa ser contada. O que falta é a ligação com o pedido — por isso não
  /// há material do SAP nem unidade de pedido, e a quantidade esperada vem da
  /// quantidade comercial do XML.
  final bool semPedido;

  /// Quantidade declarada na NF-e, na [unidade] do pedido. **Não** vai para a
  /// tela na contagem cega — só no modo supervisor.
  ///
  /// Decimal, não inteiro: material comprado em KG, L ou M vem com fração, e a
  /// contagem é feita na mesma unidade. Compare sempre com
  /// [quantidadesConferem], nunca com `==`.
  final double quantidadeNf;

  /// Unidade de medida em que se conta: a do **pedido de compra** vinculado
  /// (`IN100POs.UnidadeMedida`). Só cai para a unidade comercial do XML quando
  /// o item não tem pedido casado ([semPedido]).
  final String unidade;

  /// Material do SAP (`IN100POs.Material`). Vazio quando o item do XML não tem
  /// pedido casado.
  final String materialSap;

  /// Texto do item de pedido (`IN100POs.DescricaoMaterial`) — o nome que o SAP
  /// dá à peça.
  ///
  /// **Pode ser vazio**, e de propósito: a data layer não copia a descrição do
  /// XML para cá. Quem exibe usa [descricaoPrincipal]/[descricaoSecundaria], que
  /// resolvem o fallback sem imprimir a mesma frase duas vezes.
  final String descricaoSap;

  final String materialXml;
  final String descricaoXml;

  final ContagemItemStatus status;

  /// Quantas contagens divergentes já foram feitas neste item.
  final int tentativas;

  /// Última quantidade contada, ou `null` se ainda não houve contagem gravada.
  final double? quantidadeContada;

  /// Lote lido/digitado pelo conferente — pode diferir do [loteNf].
  final String loteLido;

  /// Número do item sem os zeros à esquerda, para a tela — o conferente lê
  /// "Item 10" na etiqueta, não "Item 00010".
  String get itemXmlLabel {
    final semZeros = itemXml.replaceFirst(RegExp(r'^0+'), '');
    return semZeros.isEmpty ? '0' : semZeros;
  }

  /// Nome que a tela mostra em destaque: o do **SAP**, que é o que o conferente
  /// precisa casar com o pedido.
  ///
  /// Cai para a descrição do XML só quando o SAP não tem nome para o item (sem
  /// pedido casado, ou pedido sem texto) — melhor a descrição do fornecedor do
  /// que um espaço em branco na frente de quem está contando.
  String get descricaoPrincipal =>
      descricaoSap.isNotEmpty ? descricaoSap : descricaoXml;

  /// Descrição do fornecedor, **só quando acrescenta informação**.
  ///
  /// `null` quando ela já é o que [descricaoPrincipal] mostra — seja porque o
  /// SAP não tem nome para o item, seja porque os dois textos são iguais.
  /// Repetir a mesma frase em duas linhas não ajuda a conferir nada e ainda
  /// esconde o resto do card num coletor de tela pequena.
  String? get descricaoSecundaria {
    if (descricaoXml.isEmpty) return null;
    return descricaoXml == descricaoPrincipal ? null : descricaoXml;
  }

  /// Material do SAP pronto para exibição. Traço quando não há pedido casado.
  String get materialSapLabel => materialSap.isEmpty ? '—' : materialSap;

  /// Pedidos na forma que o conferente lê no papel. Traço quando o item do XML
  /// não tem consumo de pedido vinculado.
  String get pedidoCompleto => pedidos.isEmpty ? '—' : pedidos.join(' · ');

  /// Lote da NF pronto para exibição (traço quando o material não tem lote).
  String get loteNfLabel => loteNf.isEmpty ? '—' : loteNf;

  /// Lote lido pronto para exibição.
  String get loteLidoLabel => loteLido.isEmpty ? '—' : loteLido;

  /// "2 PC" / "2,5 KG" — só existe depois de uma contagem gravada.
  String? get quantidadeContadaLabel {
    final contada = quantidadeContada;
    if (contada == null) return null;
    return '${formatarQuantidade(contada)} $unidade';
  }

  /// "2 PC" / "2,5 KG" — a quantidade da NF-e. Só o modo supervisor a mostra.
  String get quantidadeNfLabel => '${formatarQuantidade(quantidadeNf)} $unidade';

  ContagemItem copyWith({
    ContagemItemStatus? status,
    int? tentativas,
    double? quantidadeContada,
    String? loteLido,
  }) {
    return ContagemItem(
      itemXml: itemXml,
      loteNf: loteNf,
      pedidos: pedidos,
      semPedido: semPedido,
      quantidadeNf: quantidadeNf,
      unidade: unidade,
      materialSap: materialSap,
      descricaoSap: descricaoSap,
      materialXml: materialXml,
      descricaoXml: descricaoXml,
      status: status ?? this.status,
      tentativas: tentativas ?? this.tentativas,
      quantidadeContada: quantidadeContada ?? this.quantidadeContada,
      loteLido: loteLido ?? this.loteLido,
    );
  }

  @override
  List<Object?> get props => [
        itemXml,
        loteNf,
        pedidos,
        semPedido,
        quantidadeNf,
        unidade,
        materialSap,
        descricaoSap,
        materialXml,
        descricaoXml,
        status,
        tentativas,
        quantidadeContada,
        loteLido,
      ];
}
