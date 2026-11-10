import 'package:flutter_test/flutter_test.dart';

import '../support/token_set_contract.dart';

void main() {
  test('expectTokenSetContract aceita um conjunto que cumpre o contrato', () {
    expectTokenSetContract(
      a: const SampleTokens(1),
      // Instância não canônica, para testar a igualdade por valor.
      // ignore: prefer_const_constructors
      aCopy: SampleTokens(1),
      b: const SampleTokens(3),
    );
  });

  test('expectTokenSetContract rejeita conjuntos iguais em a e b', () {
    expect(
      () => expectTokenSetContract(
        a: const SampleTokens(1),
        // ignore: prefer_const_constructors
        aCopy: SampleTokens(1),
        b: const SampleTokens(1),
      ),
      throwsA(isA<TestFailure>()),
    );
  });
}
