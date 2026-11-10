import 'package:flutter/services.dart';

/// Máscara de CPF: 000.000.000-00 (apenas dígitos, limitado a 11).
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(limited[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Remove a máscara — o backend recebe só os dígitos.
  static String unmask(String value) => value.replaceAll(RegExp(r'\D'), '');
}

class FormCardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' '); // Add space every 4 digits
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Número decimal **positivo** com no máximo [casas] casas, sempre exibido com
/// o [separador] (vírgula por padrão).
///
/// Aceita a tecla de ponto **e** a de vírgula, porque o teclado numérico do
/// Android mostra uma ou outra conforme o locale do coletor — mas o campo
/// mostra só o [separador]: quem aperta `.` vê `,`. Assim o que o conferente
/// lê no campo é o mesmo formato dos rótulos e do log (`504,90 KG`), e não fica
/// a dúvida de se o ponto "entrou certo".
///
/// Rejeita a edição inteira (devolve o valor anterior) em vez de "consertar" o
/// texto: colar `1e5` ou digitar um segundo separador simplesmente não entra,
/// e o cursor fica onde estava.
class DecimalInputFormatter extends TextInputFormatter {
  DecimalInputFormatter({this.casas = 2, this.separador = ','})
      : assert(
          separador == ',' || separador == '.',
          'separador precisa ser "," ou "."',
        ),
        _valido = RegExp(
          casas > 0 ? '^\\d*(?:[.,]\\d{0,$casas})?\$' : r'^\d*$',
        );

  /// Casas decimais permitidas. `0` deixa o campo inteiro.
  final int casas;

  /// Separador decimal que o campo exibe. A tecla oposta é convertida.
  final String separador;

  final RegExp _valido;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_valido.hasMatch(newValue.text)) return oldValue;
    // `.` e `,` têm o mesmo tamanho, então a seleção e o composing continuam
    // apontando para os mesmos índices depois da troca.
    final outro = separador == ',' ? '.' : ',';
    final texto = newValue.text.replaceAll(outro, separador);
    return texto == newValue.text ? newValue : newValue.copyWith(text: texto);
  }
}
