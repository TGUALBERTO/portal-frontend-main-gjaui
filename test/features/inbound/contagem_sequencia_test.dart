import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/contagem_sequencia.dart';

/// `Contagem` é parte da chave primária de `INCContagemACegaLog`. Repetir um
/// número já gravado é chave duplicada — 400 no meio da conferência.
void main() {
  late ContagemSequencia sequencia;

  setUp(() => sequencia = ContagemSequencia());

  int proxima({
    String item = '00010',
    String accesskey = 'AK1',
    int maiorNoSap = 0,
  }) =>
      sequencia.proxima(
        chave: 'C1',
        accesskey: accesskey,
        item: item,
        maiorNoSap: maiorNoSap,
      );

  void registrar({
    String item = '00010',
    String accesskey = 'AK1',
    required int contagem,
  }) =>
      sequencia.registrar(
        chave: 'C1',
        accesskey: accesskey,
        item: item,
        contagem: contagem,
      );

  test('linha nunca contada começa em 1', () {
    expect(proxima(), 1);
  });

  test('o SAP manda o número quando enxerga o que já foi gravado', () {
    expect(proxima(maiorNoSap: 4), 5);
  });

  test(
      'a 2ª contagem NÃO repete o número 1 quando a releitura do SAP volta '
      'vazia', () {
    // 1ª tentativa: SAP vazio, número 1, gravado com sucesso.
    expect(proxima(maiorNoSap: 0), 1);
    registrar(contagem: 1);

    // 2ª tentativa: o SAP ainda não devolve a linha recém-gravada. Sem a marca
    // d'água isto seria 1 de novo — chave duplicada.
    expect(proxima(maiorNoSap: 0), 2);
    registrar(contagem: 2);

    expect(proxima(maiorNoSap: 0), 3);
  });

  test('a marca só sobe: registro antigo fora de ordem não rebaixa', () {
    registrar(contagem: 3);
    registrar(contagem: 1);
    expect(proxima(maiorNoSap: 0), 4);
  });

  test('o SAP vence quando está à frente — é o outro coletor na mesma nota',
      () {
    registrar(contagem: 2);
    expect(proxima(maiorNoSap: 7), 8);
  });

  test('cada item tem sua própria sequência', () {
    registrar(item: '00010', contagem: 3);
    expect(proxima(item: '00020'), 1);
    expect(proxima(item: '00010'), 4);
  });

  test(
      'lotes do mesmo item COMPARTILHAM o contador — o serviço não persiste o '
      'nLote, então contar por lote gravaria a mesma chave duas vezes', () {
    registrar(contagem: 3);
    expect(proxima(), 4);
  });

  test('cada NF-e tem sua própria sequência', () {
    registrar(accesskey: 'AK1', contagem: 3);
    expect(proxima(accesskey: 'AK2'), 1);
  });

  test('separador de chave não deixa campos vizinhos colidirem', () {
    sequencia.registrar(
      chave: 'AB',
      accesskey: 'C',
      item: 'I',
      contagem: 5,
    );
    expect(sequencia.conhecida(chave: 'A', accesskey: 'BC', item: 'I'), 0);
  });

  test('conhecida devolve 0 para linha nunca contada', () {
    expect(
        sequencia.conhecida(chave: 'C1', accesskey: 'AK1', item: '00010'), 0);
    registrar(contagem: 2);
    expect(
        sequencia.conhecida(chave: 'C1', accesskey: 'AK1', item: '00010'), 2);
  });
}
