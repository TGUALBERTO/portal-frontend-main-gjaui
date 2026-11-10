import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_quantidade.dart';

/// Parse, formato e comparação da quantidade contada — o critério é UM só para
/// tela, controller e reidratação.
void main() {
  group('parseQuantidade', () {
    test('aceita inteiro, vírgula e ponto', () {
      expect(parseQuantidade('2'), 2);
      expect(parseQuantidade('2,5'), 2.5);
      expect(parseQuantidade('2.5'), 2.5);
      expect(parseQuantidade(' 10 '), 10);
      expect(parseQuantidade('0'), 0);
    });

    test('tolera separador nas pontas', () {
      // "2," é o conferente que parou de digitar; ",5" é meio quilo.
      expect(parseQuantidade('2,'), 2);
      expect(parseQuantidade(',5'), 0.5);
      expect(parseQuantidade('.5'), 0.5);
    });

    test('vazio, só separador ou lixo é "não informado"', () {
      expect(parseQuantidade(''), isNull);
      expect(parseQuantidade('   '), isNull);
      expect(parseQuantidade(','), isNull);
      expect(parseQuantidade('.'), isNull);
      expect(parseQuantidade('abc'), isNull);
      expect(parseQuantidade('2,5,1'), isNull);
      expect(parseQuantidade('2.5.1'), isNull);
    });

    test('negativo e notação científica não passam', () {
      // O formatter da tela já bloqueia, mas o parse é a última linha: um
      // texto colado não pode virar contagem negativa nem 1e5 peças.
      expect(parseQuantidade('-1'), isNull);
      expect(parseQuantidade('1e5'), isNull);
      expect(parseQuantidade('Infinity'), isNull);
    });
  });

  group('formatarQuantidade', () {
    test('sem zeros à direita e com vírgula', () {
      expect(formatarQuantidade(2), '2');
      expect(formatarQuantidade(2.5), '2,5');
      expect(formatarQuantidade(0.125), '0,125');
      expect(formatarQuantidade(1234), '1234');
      expect(formatarQuantidade(0), '0');
    });

    test('arredonda ao que o SAP grava (4 casas)', () {
      expect(formatarQuantidade(2.00001), '2');
      expect(formatarQuantidade(2.12345), '2,1235');
      // Ruído de ponto flutuante não vaza para a tela.
      expect(formatarQuantidade(0.1 + 0.2), '0,3');
    });
  });

  group('quantidadesConferem', () {
    test('absorve ruído de ponto flutuante', () {
      expect(quantidadesConferem(0.1 + 0.2, 0.3), isTrue);
      expect(quantidadesConferem(2.5, 2.4999999999), isTrue);
      expect(quantidadesConferem(1.25 + 1.25, 2.5), isTrue);
    });

    test('diferença na última casa gravada é divergência', () {
      expect(quantidadesConferem(2.5, 2.5001), isFalse);
      expect(quantidadesConferem(2, 3), isFalse);
      expect(quantidadesConferem(0, 0.0001), isFalse);
    });
  });
}
