import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/mock/contagem_cega_mock.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_regras.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_log_registro.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_nf_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/services/rehidratar_nota.dart';

/// Reconstrução da conferência a partir do log do SAP.
///
/// É o que faz a contagem sobreviver a uma queda do coletor: sem isto, o
/// conferente recontaria do zero um caminhão inteiro.
///
/// A fixture oficial (`mockNotasFiscais`) já traz o caso difícil — o item
/// `'00030'` aparece nos lotes `C2212026` e `C2212027`, e a chave do log
/// precisa separá-los.
void main() {
  late ContagemNotaFiscal nota;

  setUp(() => nota = mockNotasFiscais().first);

  /// Registro do item `00010` (a NF pede 2 PC no lote `C2212026`).
  ContagemLogRegistro item10({
    required int contagem,
    required double quantidade,
    String lote = 'C2212026',
    String loteLido = '',
  }) =>
      ContagemLogRegistro(
        item: '00010',
        lote: lote,
        contagem: contagem,
        quantidade: quantidade,
        loteLido: loteLido,
      );

  ContagemItem primeiro(ContagemNotaFiscal n) => n.itens.first;

  test('sem registros a nota volta intacta', () {
    final resultado = rehidratarNota(nota: nota, registros: const []);

    expect(resultado, nota);
    expect(primeiro(resultado).status, ContagemItemStatus.pendente);
    expect(primeiro(resultado).tentativas, 0);
  });

  test('uma contagem que bate confere o item SEM consumir tentativa', () {
    final resultado = rehidratarNota(
      nota: nota,
      registros: [item10(contagem: 1, quantidade: 2, loteLido: 'C2212026')],
    );

    final item = primeiro(resultado);
    expect(item.status, ContagemItemStatus.ok);
    // Mesma regra de `confirmarContagem`: acerto não gasta tentativa.
    expect(item.tentativas, 0);
    expect(item.quantidadeContada, 2);
    expect(item.loteLido, 'C2212026');
  });

  test('uma contagem divergente deixa o item pendente na tentativa 2', () {
    final resultado = rehidratarNota(
      nota: nota,
      registros: [item10(contagem: 1, quantidade: 5)],
    );

    final item = primeiro(resultado);
    expect(item.status, ContagemItemStatus.pendente);
    expect(item.tentativas, 1);
    expect(item.quantidadeContada, 5);
  });

  test('duas divergências e um acerto conferem o item', () {
    final resultado = rehidratarNota(
      nota: nota,
      registros: [
        item10(contagem: 1, quantidade: 5),
        item10(contagem: 2, quantidade: 7),
        item10(contagem: 3, quantidade: 2),
      ],
    );

    final item = primeiro(resultado);
    expect(item.status, ContagemItemStatus.ok);
    expect(item.tentativas, 2);
    expect(item.quantidadeContada, 2);
  });

  test('três divergências condenam a NF-e inteira', () {
    final resultado = rehidratarNota(
      nota: nota,
      registros: [
        item10(contagem: 1, quantidade: 5),
        item10(contagem: 2, quantidade: 6),
        item10(contagem: 3, quantidade: 7),
      ],
    );

    expect(primeiro(resultado).status, ContagemItemStatus.divergente);
    expect(primeiro(resultado).tentativas, 3);
    // Uma divergência confirmada devolve a carga toda.
    expect(resultado.status, ContagemNfStatus.devolver);
  });

  test('mais divergências que o limite continuam divergentes', () {
    final resultado = rehidratarNota(
      nota: nota,
      registros: [
        for (var i = 1; i <= 5; i++) item10(contagem: i, quantidade: 9),
      ],
    );

    expect(primeiro(resultado).status, ContagemItemStatus.divergente);
    expect(primeiro(resultado).tentativas, 5);
  });

  test('a ordem do SAP não importa — o replay ordena por Contagem', () {
    // O OData V2 não garante ordem sem `$orderby`. Se o replay respeitasse a
    // ordem de chegada, este caso terminaria divergente em vez de conferido.
    final embaralhado = rehidratarNota(
      nota: nota,
      registros: [
        item10(contagem: 3, quantidade: 2),
        item10(contagem: 1, quantidade: 5),
        item10(contagem: 2, quantidade: 7),
      ],
    );

    expect(primeiro(embaralhado).status, ContagemItemStatus.ok);
    expect(primeiro(embaralhado).tentativas, 2);
  });

  test('lotes diferentes do mesmo item não se contaminam', () {
    // `00030` está nos lotes C2212026 e C2212027, ambos pedindo 4 PC.
    final resultado = rehidratarNota(
      nota: nota,
      registros: const [
        ContagemLogRegistro(
          item: '00030',
          lote: 'C2212026',
          contagem: 1,
          quantidade: 4,
        ),
      ],
    );

    final conferido = resultado.itens
        .firstWhere((i) => i.itemXml == '00030' && i.loteNf == 'C2212026');
    final intocado = resultado.itens
        .firstWhere((i) => i.itemXml == '00030' && i.loteNf == 'C2212027');

    expect(conferido.status, ContagemItemStatus.ok);
    expect(intocado.status, ContagemItemStatus.pendente);
    expect(intocado.quantidadeContada, isNull);
  });

  test('registro órfão é ignorado, não vira item fantasma', () {
    // Lote que não existe nesta nota: layout mudou no SAP ou o nome do campo
    // de lote está errado. A lista de itens vem do XML, que é a verdade do que
    // está na doca.
    final resultado = rehidratarNota(
      nota: nota,
      registros: [item10(contagem: 1, quantidade: 2, lote: 'LOTE-INEXISTENTE')],
    );

    expect(resultado.itens, hasLength(nota.itens.length));
    expect(primeiro(resultado).status, ContagemItemStatus.pendente);
  });

  test('o lote lido vem da última tentativa', () {
    final resultado = rehidratarNota(
      nota: nota,
      registros: [
        item10(contagem: 1, quantidade: 5, loteLido: 'ERRADO'),
        item10(contagem: 2, quantidade: 2, loteLido: 'C2212026'),
      ],
    );

    expect(primeiro(resultado).loteLido, 'C2212026');
  });

  test('item sem lote na NF casa com o registro de lote vazio', () {
    // O item `00020` não é controlado por lote — `loteNf` é ''.
    final resultado = rehidratarNota(
      nota: nota,
      registros: const [
        ContagemLogRegistro(
          item: '00020',
          lote: '',
          contagem: 1,
          quantidade: 3,
        ),
      ],
    );

    final item = resultado.itens.firstWhere((i) => i.itemXml == '00020');
    expect(item.status, ContagemItemStatus.ok);
    expect(item.quantidadeContada, 3);
  });

  group('lote vazio no log (o serviço não persiste o nLote enviado)', () {
    test('registro sem lote é aplicado ao item que tem uma linha só', () {
      final rehidratada = rehidratarNota(
        nota: nota,
        registros: [item10(contagem: 1, quantidade: 99, lote: '')],
      );

      final item = primeiro(rehidratada);
      expect(item.tentativas, 1,
          reason: 'a contagem existe no SAP: descartar faria a tela dizer '
              '"nunca contado" e o conferente recontaria');
      expect(item.quantidadeContada, 99);
    });

    test('registro sem lote e com lote convivem na mesma linha, em ordem', () {
      final rehidratada = rehidratarNota(
        nota: nota,
        registros: [
          item10(contagem: 2, quantidade: 98),
          item10(contagem: 1, quantidade: 99, lote: ''),
        ],
      );

      final item = primeiro(rehidratada);
      expect(item.tentativas, 2);
      // Replay na ordem de `contagem`: a última quantidade é a da tentativa 2.
      expect(item.quantidadeContada, 98);
    });

    test('registro sem lote NUNCA é chutado num item com dois lotes', () {
      final comDoisLotes =
          nota.itens.where((i) => i.itemXml == '00030').toList();
      expect(comDoisLotes.length, 2,
          reason: 'a fixture precisa manter o caso ambíguo');

      final rehidratada = rehidratarNota(
        nota: nota,
        registros: [
          const ContagemLogRegistro(
            item: '00030',
            lote: '',
            contagem: 1,
            quantidade: 99,
          ),
        ],
      );

      for (final item in rehidratada.itens.where((i) => i.itemXml == '00030')) {
        expect(item.tentativas, 0,
            reason: 'sem saber de qual lote foi, inflar a tentativa do lote '
                'errado decidiria devolução de carga por engano');
        expect(item.status, ContagemItemStatus.pendente);
      }
    });
  });


  group('rehidratarNotas — o caminhão inteiro na carga do check-in', () {
    test(
        'nota bloqueada volta como "Devolver" ao reabrir o app, sem precisar '
        'entrar nela', () {
      // O cenário do campo: conferente contou até bloquear, saiu do app e
      // voltou. As notas chegam do mapper todas `Pendente` — só o log sabe.
      final registros = [
        for (var contagem = 1; contagem <= maxTentativasContagem; contagem++)
          item10(contagem: contagem, quantidade: 999),
      ];

      final rehidratadas = rehidratarNotas(
        notas: [nota],
        registrosPorNota: {(nota.chave, nota.chaveAcesso): registros},
      );

      expect(rehidratadas.single.status, ContagemNfStatus.devolver);
    });

    test('cada registro vai para a SUA nota', () {
      final outra = ContagemNotaFiscal(
        chave: 'OUTRACHAVE',
        chaveAcesso: 'OUTRAACCESSKEY',
        numero: '999.999',
        fornecedor: 'OUTRO FORNECEDOR',
        itens: nota.itens,
      );

      final rehidratadas = rehidratarNotas(
        notas: [nota, outra],
        registrosPorNota: {
          (outra.chave, outra.chaveAcesso): [
            for (var c = 1; c <= maxTentativasContagem; c++)
              item10(contagem: c, quantidade: 999),
          ],
        },
      );

      expect(rehidratadas[0].status, ContagemNfStatus.pendente,
          reason: 'a nota sem registro no log continua intacta');
      expect(rehidratadas[1].status, ContagemNfStatus.devolver);
    });

    test('log vazio devolve as notas sem tocar nelas', () {
      final notas = [nota];
      expect(
        rehidratarNotas(notas: notas, registrosPorNota: const {}),
        same(notas),
      );
    });
  });

}
