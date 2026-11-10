import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_automation_header_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_automation_item_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_po_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_var_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_xml_item_consumo_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in_checkin_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/nota_chave.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Cruza as cinco leituras do SAP em notas prontas para a conferência.
///
/// Função **pura**: sem Dio, sem Result, sem signals. É onde mora a regra de
/// agrupamento, então é aqui que os testes batem — e é o único jeito de testar
/// isso sem rede.
///
/// Regras que valem a pena saber antes de mexer:
///
/// 1. **A espinha é [itensXml], não [consumos].** Todo item que veio na nota
///    entra na lista, tenha ou não pedido casado. Se a espinha fosse o consumo,
///    os itens que a automação não conseguiu vincular sumiriam da tela — e item
///    ausente numa contagem cega não dá erro, só passa batido.
/// 2. **A unidade de contagem é `(Item, nLote)`**, e a quantidade esperada é a
///    SOMA dos `Menge` do grupo: um mesmo lote pode ser consumido por vários
///    itens de pedido. A soma fica **decimal** — material em KG/L/M tem
///    fração, e arredondar aqui fazia a contagem certa "não bater".
/// 3. **A unidade de medida é a do pedido de compra** (`IN100POs.UnidadeMedida`):
///    é nela que o conferente conta e que o SAP compara. O `Meins` do consumo
///    é só fallback quando o item de pedido não veio na leitura, e o `UCom` do
///    XML só entra quando não há pedido nenhum.
/// 4. Nota sem item vira lista vazia, não some — o conferente precisa ver que
///    ela existe e que não há o que contar.
List<ContagemNotaFiscal> mapearNotas({
  required InCheckinDto checkin,
  required List<In100VarDto> fornecedores,
  required List<In100AutomationHeaderDto> cabecalhos,
  required List<In100AutomationItemDto> itensXml,
  required List<In100XmlItemConsumoDto> consumos,
  required List<In100PoDto> pedidos,
}) {
  final porFornecedor = {
    for (final f in fornecedores)
      NotaChave(chave: f.chave, accesskey: f.accesskey): f,
  };
  final porCabecalho = {
    for (final c in cabecalhos)
      NotaChave(chave: c.chave, accesskey: c.accesskey): c,
  };
  final porPedido = {for (final p in pedidos) p.chave: p};

  // Itens do XML agrupados por nota, e consumos agrupados por item.
  final itensPorNota = <NotaChave, List<In100AutomationItemDto>>{};
  for (final item in itensXml) {
    final id = NotaChave(chave: item.chave, accesskey: item.accesskey);
    (itensPorNota[id] ??= []).add(item);
  }
  // `Item` normalizado nos dois lados: os dois entity sets são NUMC(5), mas o
  // Gateway não os serializa igual, e errar aqui faz o item aparecer como "sem
  // pedido" — sem material do SAP, sem lote e com a quantidade do XML.
  final consumosPorItem = <String, List<In100XmlItemConsumoDto>>{};
  for (final consumo in consumos) {
    final id = '${consumo.chave}|${consumo.accesskey}|'
        '${odataNumcKey(consumo.item)}';
    (consumosPorItem[id] ??= []).add(consumo);
  }

  final notas = <ContagemNotaFiscal>[];
  for (final vinculo in checkin.itens) {
    final id = NotaChave(chave: vinculo.chave, accesskey: vinculo.accesskey);
    final fornecedor = porFornecedor[id];
    final cabecalho = porCabecalho[id];

    final itens = <ContagemItem>[];
    for (final item in itensPorNota[id] ?? const <In100AutomationItemDto>[]) {
      itens.addAll(_itensDoXml(
        item: item,
        consumos: consumosPorItem[
                '${id.chave}|${id.accesskey}|${odataNumcKey(item.item)}'] ??
            const [],
        porPedido: porPedido,
      ));
    }
    // Ordem estável: o conferente confere na sequência do DANFE.
    itens.sort((a, b) {
      final porItem = a.itemXml.compareTo(b.itemXml);
      return porItem != 0 ? porItem : a.loteNf.compareTo(b.loteNf);
    });

    notas.add(ContagemNotaFiscal(
      chave: id.chave,
      chaveAcesso: id.accesskey,
      numero: cabecalho?.numeroLabel ?? '—',
      serie: cabecalho?.serie ?? '',
      modelo: cabecalho?.modelo ?? '',
      fornecedor: fornecedor?.nomeFornecedor ?? '',
      fornecedorCodigo: fornecedor?.lifnr ?? '',
      itens: itens,
    ));
  }
  return notas;
}

/// Um item do XML vira **um** item de contagem quando não tem pedido casado, ou
/// **um por lote** quando tem.
List<ContagemItem> _itensDoXml({
  required In100AutomationItemDto item,
  required List<In100XmlItemConsumoDto> consumos,
  required Map<(String, String), In100PoDto> porPedido,
}) {
  if (consumos.isEmpty) {
    // Sem consumo de pedido não há material SAP, unidade de pedido nem lote —
    // sobra o que o XML declarou. O item entra na conferência assim mesmo: a
    // carga chegou fisicamente e alguém tem que contar.
    return [
      ContagemItem(
        itemXml: item.item,
        loteNf: '',
        pedidos: const [],
        semPedido: true,
        quantidadeNf: item.quantidadeComercial ?? 0,
        unidade: item.unidadeComercial,
        materialSap: '',
        // Vazia, e não a descrição do XML: sem pedido casado o SAP não tem nome
        // para este item, e copiar o do XML fazia a tela imprimir a mesma
        // frase duas vezes. Quem decide o fallback de exibição é
        // `ContagemItem.descricaoPrincipal`.
        descricaoSap: '',
        materialXml: item.codigoProduto,
        descricaoXml: item.descricaoProduto,
      ),
    ];
  }

  final porLote = <String, List<In100XmlItemConsumoDto>>{};
  for (final consumo in consumos) {
    (porLote[consumo.lote] ??= []).add(consumo);
  }

  return porLote.entries.map((entrada) {
    final lote = entrada.key;
    final grupo = entrada.value;

    final esperada = grupo.fold<double>(
      0,
      (soma, c) => soma + (c.quantidade ?? 0),
    );

    // Unidade do **pedido de compra** primeiro: é a que o conferente vê na
    // tela e em que a quantidade esperada está. O `Meins` do consumo cobre o
    // item de pedido que não veio no IN100POs; sem nenhum dos dois, sobra a
    // unidade comercial do XML.
    final unidadesPedido = grupo
        .map((c) => porPedido[c.chavePedido]?.unidade ?? '')
        .where((u) => u.isNotEmpty)
        .toSet();
    final unidadesConsumo =
        grupo.map((c) => c.unidade).where((u) => u.isNotEmpty).toSet();
    final unidades = unidadesPedido.isNotEmpty ? unidadesPedido : unidadesConsumo;
    if (unidades.length > 1) {
      // Somar quantidades de unidades diferentes não significa nada. Não dá
      // para decidir aqui qual é a certa, mas o log tem que registrar — senão a
      // divergência aparece na doca sem explicação.
      AppLogger.warning(
        'Contagem cega: item ${item.item} lote "$lote" tem unidades '
        'divergentes entre os itens de pedido ($unidades). Usando a primeira.',
      );
    }

    final materiais = grupo
        .map((c) => porPedido[c.chavePedido]?.material ?? '')
        .where((m) => m.isNotEmpty)
        .toSet();
    final descricoes = grupo
        .map((c) => porPedido[c.chavePedido]?.descricaoMaterial ?? '')
        .where((d) => d.isNotEmpty)
        .toSet();

    if (descricoes.isEmpty) {
      // A tela cai para a descrição do XML e o conferente não percebe que está
      // sem o nome do SAP. Duas causas, e o log separa as duas: o item de
      // pedido não veio na leitura (cruzamento), ou veio sem `MAKTX` (cadastro
      // de material sem texto no idioma da sessão do usuário de serviço).
      final semPedido =
          grupo.where((c) => porPedido[c.chavePedido] == null).toList();
      AppLogger.warning(
        semPedido.isEmpty
            ? 'Contagem cega: item ${item.item} lote "$lote" tem pedido '
                'casado, mas `DescricaoMaterial` veio vazia no IN100POs — '
                'confira o texto do material no idioma da sessão SAP.'
            : 'Contagem cega: item ${item.item} lote "$lote" não achou os '
                'itens de pedido ${semPedido.map((c) => c.pedidoLabel).toSet()} '
                'no IN100POs. A tela fica sem o nome do material do SAP.',
      );
    }

    return ContagemItem(
      itemXml: item.item,
      loteNf: lote,
      pedidos: grupo.map((c) => c.pedidoLabel).toSet().toList(growable: false),
      quantidadeNf: esperada,
      unidade: unidades.isEmpty ? item.unidadeComercial : unidades.first,
      materialSap: materiais.length == 1 ? materiais.first : materiais.join(' · '),
      // Só o texto do item de pedido (`IN100POs.DescricaoMaterial`). Vazio
      // quando o pedido não trouxe descrição — o fallback para o XML é da
      // camada de exibição, senão a tela repete a mesma frase nas duas linhas.
      descricaoSap: descricoes.isEmpty ? '' : descricoes.first,
      materialXml: item.codigoProduto,
      descricaoXml: item.descricaoProduto,
    );
  }).toList(growable: false);
}
