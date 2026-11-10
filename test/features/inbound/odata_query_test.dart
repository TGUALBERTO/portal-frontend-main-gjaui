import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_query.dart';

/// O `$filter` é montado como string crua e vai para o SAP Gateway. Um escape
/// errado aqui não dá erro de compilação — dá 400 no coletor, na doca.
void main() {
  group('odataLiteral', () {
    test('envolve em aspas simples', () {
      expect(odataLiteral('ABC'), "'ABC'");
    });

    test('duplica a aspa interna', () {
      // Sem isto o literal fecharia em D e o resto viraria sintaxe.
      expect(odataLiteral("D'ANGELO"), "'D''ANGELO'");
    });

    test('preserva string vazia', () {
      // nLote é key NOT NULL no SAP e chega como '' quando o material não tem
      // lote — o filtro precisa conseguir procurar por isso.
      expect(odataLiteral(''), "''");
    });
  });

  group('odataKey', () {
    test('monta o key predicate composto', () {
      expect(
        odataKey({'Chave': 'AUT01', 'Accesskey': '5226'}),
        "Chave='AUT01',Accesskey='5226'",
      );
    });

    test('escapa a aspa também na key', () {
      expect(odataKey({'Chave': "D'A"}), "Chave='D''A'");
    });
  });

  group('odataAnyOf', () {
    test('junta os valores com or', () {
      expect(
        odataAnyOf('Accesskey', ['A1', 'A2']),
        "Accesskey eq 'A1' or Accesskey eq 'A2'",
      );
    });

    test('deduplica', () {
      expect(odataAnyOf('Accesskey', ['A1', 'A1']), "Accesskey eq 'A1'");
    });

    test('devolve null quando não há valor', () {
      // `$filter=` vazio é erro no Gateway; o chamador tem que omitir o
      // parâmetro inteiro.
      expect(odataAnyOf('Accesskey', const []), isNull);
    });
  });

  group('odataAnyOfPairs', () {
    test('parenteriza cada par', () {
      // Sem os parênteses o `and` teria precedência sobre o `or` e o filtro
      // casaria linhas erradas.
      expect(
        odataAnyOfPairs('Chave', 'Accesskey', [('C1', 'A1'), ('C2', 'A2')]),
        "(Chave eq 'C1' and Accesskey eq 'A1') or "
        "(Chave eq 'C2' and Accesskey eq 'A2')",
      );
    });

    test('deduplica pares idênticos', () {
      expect(
        odataAnyOfPairs('Chave', 'Accesskey', [('C1', 'A1'), ('C1', 'A1')]),
        "(Chave eq 'C1' and Accesskey eq 'A1')",
      );
    });

    test('devolve null quando não há par', () {
      expect(odataAnyOfPairs('Chave', 'Accesskey', const []), isNull);
    });
  });

  group('emLotes', () {
    test('quebra no tamanho pedido sem perder item', () {
      final lotes = emLotes(List.generate(45, (i) => i), tamanho: 20).toList();
      expect(lotes.map((l) => l.length), [20, 20, 5]);
      expect(lotes.expand((l) => l), List.generate(45, (i) => i));
    });

    test('lista menor que o lote vira um lote só', () {
      expect(emLotes([1, 2], tamanho: 20).toList(), [
        [1, 2],
      ]);
    });

    test('lista vazia não gera lote', () {
      expect(emLotes(const <int>[], tamanho: 20), isEmpty);
    });

    test('tamanho inválido é erro de programação', () {
      expect(() => emLotes([1], tamanho: 0).toList(), throwsArgumentError);
    });
  });
}
