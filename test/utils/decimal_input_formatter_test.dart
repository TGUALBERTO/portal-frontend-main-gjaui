import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/utils/input_formatters.dart';

/// O campo de quantidade da contagem cega: decimal, vírgula ou ponto, casas
/// limitadas ao que o SAP grava.
void main() {
  String digitar(DecimalInputFormatter f, String antes, String depois) => f
      .formatEditUpdate(
        TextEditingValue(text: antes),
        TextEditingValue(text: depois),
      )
      .text;

  final quatro = DecimalInputFormatter(casas: 4);

  test('aceita dígitos e um separador', () {
    expect(digitar(quatro, '', '2'), '2');
    expect(digitar(quatro, '2', '2,'), '2,');
    expect(digitar(quatro, '2,', '2,5'), '2,5');
    // Começar pelo separador é meio quilo a caminho.
    expect(digitar(quatro, '', ','), ',');
  });

  test('a tecla de ponto vira vírgula na hora', () {
    // O teclado do coletor pode só ter ponto; o campo mostra o formato pt-BR
    // de qualquer jeito, igual aos rótulos e ao log.
    expect(digitar(quatro, '2', '2.'), '2,');
    expect(digitar(quatro, '2,', '2,5'), '2,5');
    expect(digitar(quatro, '', '504.90'), '504,90');
  });

  test('o cursor não se perde na troca do separador', () {
    final valor = quatro.formatEditUpdate(
      const TextEditingValue(text: '504'),
      const TextEditingValue(
        text: '504.',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    expect(valor.text, '504,');
    expect(valor.selection.baseOffset, 4);
  });

  test('pode exibir ponto quando pedido', () {
    final ponto = DecimalInputFormatter(casas: 2, separador: '.');
    expect(digitar(ponto, '2', '2,'), '2.');
    expect(digitar(ponto, '2.', '2.5'), '2.5');
  });

  test('rejeita segundo separador, letras e sinal — o campo fica como estava',
      () {
    expect(digitar(quatro, '2,5', '2,5,'), '2,5');
    expect(digitar(quatro, '2,5', '2,5.'), '2,5');
    expect(digitar(quatro, '2,5', '2,5a'), '2,5');
    expect(digitar(quatro, '', '-'), '');
    expect(digitar(quatro, '1', '1e5'), '1');
  });

  test('limita as casas decimais', () {
    expect(digitar(quatro, '2,1234', '2,12345'), '2,1234');
    expect(digitar(quatro, '2,123', '2,1234'), '2,1234');
  });

  test('apagar tudo é permitido', () {
    expect(digitar(quatro, '2,5', ''), '');
  });

  test('com zero casas o campo é inteiro', () {
    final inteiro = DecimalInputFormatter(casas: 0);
    expect(digitar(inteiro, '2', '2,'), '2');
    expect(digitar(inteiro, '2', '25'), '25');
  });
}
