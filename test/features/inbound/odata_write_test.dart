import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_write.dart';

/// Formatos de escrita do OData V2. São strings que o Gateway rejeita com 400
/// se saírem por um caractere — e o erro só aparece no coletor, na doca.
void main() {
  group('odataDate', () {
    test('serializa a data como meia-noite UTC em milissegundos', () {
      // Valor conferido contra o payload real do SAP.
      expect(
        odataDate(DateTime(2026, 8, 14, 16, 54, 35)),
        '/Date(1786665600000)/',
      );
    });

    test('a hora do dia não muda o resultado', () {
      // Regressão contra a implementação ingênua `momento.toUtc()`: num coletor
      // em UTC-3, contar às 21h gravaria o dia SEGUINTE, e o `Credat` deixaria
      // de bater com o `Cretim` do mesmo instante.
      expect(
        odataDate(DateTime(2026, 8, 14, 23, 59, 59)),
        odataDate(DateTime(2026, 8, 14)),
      );
      expect(
        odataDate(DateTime(2026, 8, 14, 0, 0, 1)),
        odataDate(DateTime(2026, 8, 14)),
      );
    });
  });

  group('odataTime', () {
    test('emite a duração ISO-8601 desde a meia-noite', () {
      expect(odataTime(DateTime(2026, 8, 14, 16, 54, 35)), 'PT16H54M35S');
    });

    test('zero-pada os três componentes', () {
      expect(odataTime(DateTime(2026, 8, 14, 9, 5, 3)), 'PT09H05M03S');
    });

    test('meia-noite tem os três componentes, não string vazia', () {
      expect(odataTime(DateTime(2026, 8, 14)), 'PT00H00M00S');
    });
  });

  group('odataDecimalString', () {
    test('Edm.Decimal viaja como string com 4 casas', () {
      expect(odataDecimalString(123), '123.0000');
      expect(odataDecimalString(0), '0.0000');
    });

    test('respeita a escala pedida', () {
      expect(odataDecimalString(2, casas: 3), '2.000');
    });

    test('nunca usa vírgula', () {
      // O app roda em pt_BR: um `NumberFormat` produziria `123,0000` e o SAP
      // responderia 400.
      for (final valor in [1, 1000, 0.5, 12345.678]) {
        expect(odataDecimalString(valor), isNot(contains(',')));
      }
    });
  });

  group('odataNumc', () {
    test('zero-pada até a largura', () {
      expect(odataNumc(1, 3), '001');
      expect(odataNumc(42, 3), '042');
      expect(odataNumc(999, 3), '999');
    });

    test('estoura quando não cabe em vez de truncar', () {
      // Truncar corromperia a chave primária — num log append-only isso é
      // sobrescrever a tentativa de outra pessoa.
      expect(() => odataNumc(1000, 3), throwsArgumentError);
    });

    test('recusa negativo', () {
      expect(() => odataNumc(-1, 3), throwsArgumentError);
    });
  });
}
