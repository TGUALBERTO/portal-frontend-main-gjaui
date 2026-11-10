import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/inc_contagem_a_cega_header_dto.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_header_status.dart';

/// Tradução do `Status` do `INCContagemACegaHeader`.
///
/// Vale um teste próprio porque é uma letra: trocar `'C'` por `'D'` aqui não
/// quebra compilação nem estoura em runtime — só libera o botão de finalizar
/// num check-in que o SAP já fechou, que é exatamente o que este bloqueio
/// existe para impedir.
void main() {
  ContagemHeaderStatus statusDe(Map<String, dynamic> json) =>
      IncContagemACegaHeaderDto.fromJson(json).statusContagem;

  test("'C' e 'D' são os únicos que contam como finalizado", () {
    expect(
      statusDe({'Checkin': '0000000003', 'Status': 'C'}),
      ContagemHeaderStatus.finalizadoConforme,
    );
    expect(
      statusDe({'Checkin': '0000000003', 'Status': 'D'}),
      ContagemHeaderStatus.finalizadoDivergente,
    );

    expect(ContagemHeaderStatus.finalizadoConforme.finalizado, isTrue);
    expect(ContagemHeaderStatus.finalizadoDivergente.finalizado, isTrue);
  });

  test("'E' é conferência aberta — o estado normal durante a contagem", () {
    final status = statusDe({'Checkin': '0000000003', 'Status': 'E'});
    expect(status, ContagemHeaderStatus.aberto);
    expect(status.finalizado, isFalse);
  });

  test('cabeçalho ausente é inexistente, não desconhecido', () {
    // 404 na leitura pela key, e também a entidade em branco que alguma
    // configuração de Gateway devolve no lugar dele.
    expect(statusDe(const {}), ContagemHeaderStatus.inexistente);
    expect(
      statusDe({'Checkin': '', 'Status': 'C'}),
      ContagemHeaderStatus.inexistente,
    );
    expect(ContagemHeaderStatus.inexistente.finalizado, isFalse);
  });

  test('letra desconhecida não bloqueia', () {
    // Travar a doca porque o SAP passou a gravar um status intermediário é pior
    // que deixar finalizar: só 'C'/'D' significam "já processado".
    final status = statusDe({'Checkin': '0000000003', 'Status': 'X'});
    expect(status, ContagemHeaderStatus.desconhecido);
    expect(status.finalizado, isFalse);
  });

  test('status vem normalizado — o SAP devolve CHAR com padding', () {
    expect(
      statusDe({'Checkin': '0000000003', 'Status': ' c '}),
      ContagemHeaderStatus.finalizadoConforme,
    );
  });

  test('só quem finaliza tem frase de bloqueio para a tela', () {
    for (final status in ContagemHeaderStatus.values) {
      expect(status.situacao.isNotEmpty, status.finalizado, reason: status.name);
    }
  });
}
