/// Uma violação encontrada por uma verificação de conformidade.
class Violation {
  /// Cria uma violação da verificação [check] no arquivo [path].
  const Violation(this.check, this.path, this.message, {this.line});

  /// Nome da verificação que encontrou a violação (por exemplo, `tokens`).
  final String check;

  /// Caminho relativo à raiz do repositório, com `/` como separador.
  final String path;

  /// Linha (base 1) da violação, quando aplicável.
  final int? line;

  /// Descrição legível da violação.
  final String message;

  @override
  String toString() =>
      '[$check] $path${line == null ? '' : ':$line'}: $message';
}
