import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_automation_header_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_automation_item_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_po_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_var_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in100_xml_item_consumo_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/in_checkin_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/mappers/contagem_cega_mapper.dart';

/// O mapper cruza cinco leituras do SAP num modelo só. É a peça com mais regra
/// e a única testável sem rede — os JSONs abaixo são o formato real do OData V2
/// (Decimal como string, `$expand` embrulhado em `results`).
void main() {
  const chave = 'AUT001';
  const accesskey = '52260450143483000151550020000077961000213831';

  InCheckinDto checkinCom(List<String> accesskeys) =>
      InCheckinDto.fromJson({
        'Checkin': '0000000003',
        'Status': 'L',
        'Motorista': 'João da Silva',
        'Cpf': '12345678901',
        'Placa': 'ABC1D23',
        'to_Items': {
          'results': [
            for (final a in accesskeys)
              {
                'Checkin': '0000000003',
                'Chave': chave,
                'Accesskey': a,
                'Status': 'A',
              },
          ],
        },
      });

  In100AutomationItemDto itemXml({
    required String item,
    String cprod = 'CP1',
    String xprod = 'PECA DO XML',
    String ucom = 'CX',
    String qcom = '5.0000',
  }) =>
      In100AutomationItemDto.fromJson({
        'Chave': chave,
        'Accesskey': accesskey,
        'Item': item,
        'CProd': cprod,
        'XProd': xprod,
        'UCom': ucom,
        'QCom': qcom,
      });

  In100XmlItemConsumoDto consumo({
    required String item,
    required String lote,
    required String menge,
    String ebeln = '4501548574',
    String ebelp = '00010',
    String meins = 'PC',
  }) =>
      In100XmlItemConsumoDto.fromJson({
        'Chave': chave,
        'Accesskey': accesskey,
        'Item': item,
        'nLote': lote,
        'Ebeln': ebeln,
        'Ebelp': ebelp,
        'Menge': menge,
        'Meins': meins,
      });

  In100PoDto po({
    String ebeln = '4501548574',
    String ebelp = '00010',
    String material = '6000857',
    String descricao = 'CORREIA VA 60',
    String unidade = 'PC',
  }) =>
      In100PoDto.fromJson({
        'PedidoCompra': ebeln,
        'Item': ebelp,
        'Material': material,
        'DescricaoMaterial': descricao,
        'UnidadeMedida': unidade,
      });

  final cabecalho = In100AutomationHeaderDto.fromJson({
    'Chave': chave,
    'Accesskey': accesskey,
    'NNf': '000021383',
    'Serie': '002',
    'Mod': '55',
  });

  final fornecedor = In100VarDto.fromJson({
    'Chave': chave,
    'Accesskey': accesskey,
    'Lifnr': '0000105432',
    'NomeFornecedor': 'TRANSPOWER IND. LTDA',
  });

  List<dynamic> mapear({
    List<In100AutomationItemDto> itens = const [],
    List<In100XmlItemConsumoDto> consumos = const [],
    List<In100PoDto> pedidos = const [],
    List<In100VarDto>? fornecedores,
    List<In100AutomationHeaderDto>? cabecalhos,
  }) =>
      mapearNotas(
        checkin: checkinCom([accesskey]),
        fornecedores: fornecedores ?? [fornecedor],
        cabecalhos: cabecalhos ?? [cabecalho],
        itensXml: itens,
        consumos: consumos,
        pedidos: pedidos,
      );

  test('monta a nota com número sem zeros, série e fornecedor', () {
    final notas = mapear();

    expect(notas, hasLength(1));
    final nota = notas.single;
    expect(nota.chave, chave);
    expect(nota.chaveAcesso, accesskey);
    expect(nota.numero, '21383');
    expect(nota.serie, '002');
    expect(nota.fornecedor, 'TRANSPOWER IND. LTDA');
    expect(nota.fornecedorCodigo, '0000105432');
  });

  test('sem NomeFornecedor, cai para o código do fornecedor', () {
    // O campo ainda vai ser publicado pelo time SAP; até lá o JSON não o traz.
    final semNome = In100VarDto.fromJson({
      'Chave': chave,
      'Accesskey': accesskey,
      'Lifnr': '0000105432',
    });

    final nota = mapear(fornecedores: [semNome]).single;
    expect(nota.fornecedor, isEmpty);
    expect(nota.fornecedorLabel, '0000105432');
  });

  test('quantidade esperada é a SOMA dos Menge do mesmo (item, lote)', () {
    // Um lote consumido por dois itens de pedido: 2 + 3 = 5.
    final nota = mapear(
      itens: [itemXml(item: '00010')],
      consumos: [
        consumo(item: '00010', lote: 'L1', menge: '2.000', ebelp: '00010'),
        consumo(item: '00010', lote: 'L1', menge: '3.000', ebelp: '00020'),
      ],
      pedidos: [po(ebelp: '00010'), po(ebelp: '00020')],
    ).single;

    expect(nota.itens, hasLength(1));
    expect(nota.itens.single.quantidadeNf, 5);
    expect(nota.itens.single.unidade, 'PC');
  });

  test('mesmo item em dois lotes vira duas contagens', () {
    final nota = mapear(
      itens: [itemXml(item: '00030')],
      consumos: [
        consumo(item: '00030', lote: 'C2212026', menge: '4.000'),
        consumo(item: '00030', lote: 'C2212027', menge: '4.000'),
      ],
      pedidos: [po()],
    ).single;

    expect(nota.itens, hasLength(2));
    expect(nota.itens.map((i) => i.loteNf), ['C2212026', 'C2212027']);
    expect(nota.itens.every((i) => i.quantidadeNf == 4), isTrue);
  });

  test('material sem lote vem com nLote vazio e conta normalmente', () {
    // `nLote` é key NOT NULL no SAP: chega como '' e não como null.
    final nota = mapear(
      itens: [itemXml(item: '00020')],
      consumos: [consumo(item: '00020', lote: '', menge: '3.000')],
      pedidos: [po()],
    ).single;

    expect(nota.itens, hasLength(1));
    expect(nota.itens.single.loteNf, isEmpty);
    expect(nota.itens.single.loteNfLabel, '—');
    expect(nota.itens.single.quantidadeNf, 3);
  });

  test('item do XML SEM consumo de pedido continua na conferência', () {
    // A regra mais importante: se a espinha fosse o consumo, este item sumiria
    // da tela — e item que some de uma contagem cega passa batido.
    final nota = mapear(
      itens: [
        itemXml(item: '00010'),
        itemXml(item: '00090', cprod: 'ORFAO', xprod: 'ITEM SEM PEDIDO'),
      ],
      consumos: [consumo(item: '00010', lote: 'L1', menge: '2.000')],
      pedidos: [po()],
    ).single;

    expect(nota.itens, hasLength(2));

    final orfao = nota.itens.firstWhere((i) => i.itemXml == '00090');
    expect(orfao.semPedido, isTrue);
    expect(orfao.pedidos, isEmpty);
    expect(orfao.pedidoCompleto, '—');
    expect(orfao.materialSap, isEmpty);
    // Sem pedido o SAP não tem nome para o item, e o campo fica vazio — copiar
    // a descrição do XML para cá fazia a tela imprimir a mesma frase duas
    // vezes. O fallback de exibição é do `descricaoPrincipal`.
    expect(orfao.descricaoSap, isEmpty);
    expect(orfao.descricaoPrincipal, 'ITEM SEM PEDIDO');
    expect(orfao.descricaoSecundaria, isNull);
    expect(orfao.quantidadeNf, 5); // QCom
    expect(orfao.unidade, 'CX'); // UCom, não Meins
  });

  test('item com dois pedidos lista os dois', () {
    final item = mapear(
      itens: [itemXml(item: '00010')],
      consumos: [
        consumo(item: '00010', lote: 'L1', menge: '2.000', ebelp: '00010'),
        consumo(item: '00010', lote: 'L1', menge: '3.000', ebelp: '00020'),
      ],
      pedidos: [po(ebelp: '00010'), po(ebelp: '00020')],
    ).single.itens.single;

    expect(item.pedidos, ['4501548574 / 10', '4501548574 / 20']);
    expect(item.pedidoCompleto, '4501548574 / 10 · 4501548574 / 20');
  });

  test('materiais diferentes no mesmo lote são listados, não escolhidos', () {
    final item = mapear(
      itens: [itemXml(item: '00010')],
      consumos: [
        consumo(item: '00010', lote: 'L1', menge: '2.000', ebelp: '00010'),
        consumo(item: '00010', lote: 'L1', menge: '3.000', ebelp: '00020'),
      ],
      pedidos: [
        po(ebelp: '00010', material: '6000857'),
        po(ebelp: '00020', material: '6009999'),
      ],
    ).single.itens.single;

    // Escolher um em silêncio faria o conferente conferir contra o material
    // errado.
    expect(item.materialSap, '6000857 · 6009999');
  });

  test('material do SAP e descrição vêm do item do pedido', () {
    final item = mapear(
      itens: [itemXml(item: '00010', cprod: '20015949', xprod: 'A60 CORREIA')],
      consumos: [consumo(item: '00010', lote: 'C2212026', menge: '2.000')],
      pedidos: [po()],
    ).single.itens.single;

    expect(item.materialSap, '6000857');
    expect(item.descricaoSap, 'CORREIA VA 60');
    expect(item.materialXml, '20015949');
    expect(item.descricaoXml, 'A60 CORREIA');
    expect(item.itemXml, '00010');
    expect(item.itemXmlLabel, '10');
  });

  test('nota sem item vira lista vazia, mas a nota não some', () {
    final nota = mapear().single;
    expect(nota.itens, isEmpty);
    expect(nota.totalItens, 0);
  });

  test('cabeçalho ausente não derruba a nota', () {
    final nota = mapear(cabecalhos: const []).single;
    expect(nota.numero, '—');
    expect(nota.chaveAcesso, accesskey);
  });

  test('itens saem na ordem do DANFE (item, depois lote)', () {
    final nota = mapear(
      itens: [itemXml(item: '00030'), itemXml(item: '00010')],
      consumos: [
        consumo(item: '00030', lote: 'B', menge: '1.000'),
        consumo(item: '00030', lote: 'A', menge: '1.000'),
        consumo(item: '00010', lote: '', menge: '1.000'),
      ],
      pedidos: [po()],
    ).single;

    expect(
      nota.itens.map((i) => '${i.itemXml}/${i.loteNf}'),
      ['00010/', '00030/A', '00030/B'],
    );
  });

  test('Decimal chega como string e é parseado', () {
    // OData V2 serializa Edm.Decimal como STRING; um `as num` estouraria aqui.
    final item = mapear(
      itens: [itemXml(item: '00010')],
      consumos: [consumo(item: '00010', lote: 'L1', menge: '12.000')],
      pedidos: [po()],
    ).single.itens.single;

    expect(item.quantidadeNf, 12);
  });

  group('nome do material do SAP', () {
    test('vem do IN100POs, e a descrição do XML fica na linha secundária', () {
      final nota = mapear(
        itens: [itemXml(item: '00010', xprod: 'PECA DO FORNECEDOR')],
        consumos: [consumo(item: '00010', lote: 'L1', menge: '2.000')],
        pedidos: [po(descricao: 'CORREIA VA 60')],
      ).single;

      final item = nota.itens.single;
      expect(item.descricaoSap, 'CORREIA VA 60');
      expect(item.descricaoPrincipal, 'CORREIA VA 60');
      expect(item.descricaoSecundaria, 'PECA DO FORNECEDOR');
      expect(item.materialSapLabel, '6000857');
    });

    test(
        'casa o item do pedido mesmo com NUMC serializado diferente nos dois '
        'entity sets', () {
      final nota = mapear(
        itens: [itemXml(item: '00010')],
        // `Ebelp` zero-padded no consumo...
        consumos: [
          consumo(item: '00010', lote: 'L1', menge: '2.000', ebelp: '00010')
        ],
        // ...e sem zeros no IN100POs. É o mesmo item de pedido.
        pedidos: [po(ebelp: '10', descricao: 'CORREIA VA 60')],
      ).single;

      expect(nota.itens.single.descricaoSap, 'CORREIA VA 60',
          reason: 'cruzamento que erra deixa a tela sem o nome do SAP e '
              'repetindo a descrição do fornecedor');
    });

    test('sem pedido casado não copia a descrição do XML para o campo do SAP',
        () {
      final nota = mapear(
        itens: [itemXml(item: '00010', xprod: 'PECA DO FORNECEDOR')],
      ).single;

      final item = nota.itens.single;
      expect(item.descricaoSap, isEmpty);
      expect(item.materialSapLabel, '—');
      // A tela ainda mostra algo — mas UMA vez, não duas.
      expect(item.descricaoPrincipal, 'PECA DO FORNECEDOR');
      expect(item.descricaoSecundaria, isNull);
    });

    test('pedido sem DescricaoMaterial não repete a descrição na tela', () {
      final nota = mapear(
        itens: [itemXml(item: '00010', xprod: 'PECA DO FORNECEDOR')],
        consumos: [consumo(item: '00010', lote: 'L1', menge: '2.000')],
        pedidos: [po(descricao: '')],
      ).single;

      final item = nota.itens.single;
      expect(item.descricaoPrincipal, 'PECA DO FORNECEDOR');
      expect(item.descricaoSecundaria, isNull);
      expect(item.materialSapLabel, '6000857',
          reason: 'o material existe; o que faltou foi o texto');
    });

    test('descrições idênticas nos dois lados não viram duas linhas', () {
      final nota = mapear(
        itens: [itemXml(item: '00010', xprod: 'CORREIA VA 60')],
        consumos: [consumo(item: '00010', lote: 'L1', menge: '2.000')],
        pedidos: [po(descricao: 'CORREIA VA 60')],
      ).single;

      expect(nota.itens.single.descricaoSecundaria, isNull);
    });
  });

  group('unidade de medida', () {
    test('é a do pedido de compra (IN100POs), não o Meins nem o UCom', () {
      final item = mapear(
        itens: [itemXml(item: '00010', ucom: 'CX')],
        consumos: [
          consumo(item: '00010', lote: 'L1', menge: '2.500', meins: 'UN'),
        ],
        pedidos: [po(unidade: 'KG')],
      ).single.itens.single;

      // É nela que o conferente conta e que o SAP compara — mostrar a unidade
      // comercial do fornecedor faria contar caixas onde o pedido é em quilo.
      expect(item.unidade, 'KG');
      expect(item.quantidadeNfLabel, '2,5 KG');
    });

    test('sem o item de pedido na leitura cai para o Meins do consumo', () {
      final item = mapear(
        itens: [itemXml(item: '00010', ucom: 'CX')],
        consumos: [
          consumo(item: '00010', lote: 'L1', menge: '2.000', meins: 'UN'),
        ],
        // Nenhum IN100POs devolvido para este pedido.
        pedidos: const [],
      ).single.itens.single;

      expect(item.unidade, 'UN');
    });

    test('pedido sem UnidadeMedida também cai para o Meins', () {
      final item = mapear(
        itens: [itemXml(item: '00010', ucom: 'CX')],
        consumos: [
          consumo(item: '00010', lote: 'L1', menge: '2.000', meins: 'UN'),
        ],
        pedidos: [po(unidade: '')],
      ).single.itens.single;

      expect(item.unidade, 'UN');
    });
  });

  group('quantidade decimal', () {
    test('a soma dos Menge NÃO é arredondada', () {
      // Material em KG: 1,250 + 1,250 = 2,5. Arredondar para 3 faria a
      // contagem certa "não bater" e condenar a NF-e.
      final item = mapear(
        itens: [itemXml(item: '00010')],
        consumos: [
          consumo(item: '00010', lote: 'L1', menge: '1.250', ebelp: '00010'),
          consumo(item: '00010', lote: 'L1', menge: '1.250', ebelp: '00020'),
        ],
        pedidos: [po(ebelp: '00010', unidade: 'KG'), po(ebelp: '00020', unidade: 'KG')],
      ).single.itens.single;

      expect(item.quantidadeNf, closeTo(2.5, 1e-9));
      expect(item.quantidadeNfLabel, '2,5 KG');
    });

    test('item sem pedido mantém a fração do QCom', () {
      final item = mapear(
        itens: [itemXml(item: '00090', qcom: '0.7500', ucom: 'L')],
      ).single.itens.single;

      expect(item.quantidadeNf, closeTo(0.75, 1e-9));
      expect(item.quantidadeNfLabel, '0,75 L');
    });
  });
}
