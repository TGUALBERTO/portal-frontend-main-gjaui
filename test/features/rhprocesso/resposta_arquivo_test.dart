import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/rhprocesso/data/resposta_arquivo.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/arquivo_gerado.dart';
import 'dart:typed_data';

void main() {
  group('nomeDoContentDisposition', () {
    test('filename entre aspas (formato do Spring)', () {
      expect(
        nomeDoContentDisposition('attachment; filename="202609_JOAO SILVA_12345.pdf"'),
        '202609_JOAO SILVA_12345.pdf',
      );
    });

    test('filename* (RFC 5987) tem prioridade e é decodificado', () {
      expect(
        nomeDoContentDisposition(
          "attachment; filename=\"x.pdf\"; filename*=UTF-8''202609_JO%C3%83O_1.pdf",
        ),
        '202609_JOÃO_1.pdf',
      );
    });

    test('filename sem aspas', () {
      expect(nomeDoContentDisposition('attachment; filename=volume.xlsx'), 'volume.xlsx');
    });

    test('sem cabeçalho ou sem filename devolve null', () {
      expect(nomeDoContentDisposition(null), isNull);
      expect(nomeDoContentDisposition('attachment'), isNull);
    });
  });

  test('ArquivoGerado separa nome e extensão para o FileSaver', () {
    final a = ArquivoGerado(nome: '202609_JOAO_12345.pdf', bytes: Uint8List(0));
    expect(a.nomeBase, '202609_JOAO_12345');
    expect(a.extensao, 'pdf');
  });
}
