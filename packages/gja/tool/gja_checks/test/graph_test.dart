import 'package:gja_checks/gja_checks.dart';
import 'package:test/test.dart';

void main() {
  test('grafo acíclico não tem ciclos', () {
    expect(findCycles({'a': {'b'}, 'b': {'c'}, 'c': {}}), isEmpty);
  });

  test('ciclo é retornado como caminho fechado real', () {
    expect(findCycles({'a': {'b'}, 'b': {'c', 'd'}, 'c': {'a'}, 'd': {}}), [
      ['a', 'b', 'c', 'a'],
    ]);
  });

  test('laço é um ciclo', () {
    expect(findCycles({'a': {'a'}}), [
      ['a', 'a'],
    ]);
  });

  test('componentes independentes geram um ciclo cada', () {
    expect(findCycles({'a': {'b'}, 'b': {'a'}, 'x': {'y'}, 'y': {'x'}}), hasLength(2));
  });
}
