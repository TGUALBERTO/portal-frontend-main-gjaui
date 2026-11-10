import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/contagem_cega_ecc_campos.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/inc_contagem_a_cega_campos.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/repositories/contagem_cega_repository_router.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/sap_backend.dart';

import 'fakes/fake_contagem_cega.dart';

void main() {
  group('SapPlataforma', () {
    test('Bandeirantes é ECC; NEL e Vitamedic são S/4HANA', () {
      expect(BackendService.sapBandeirantes.sapPlataforma, SapPlataforma.ecc);
      expect(BackendService.sapNel.sapPlataforma, SapPlataforma.s4hana);
      expect(BackendService.sapVitamedic.sapPlataforma, SapPlataforma.s4hana);
    });

    test('backend que não é SAP não tem plataforma', () {
      expect(BackendService.core.sapPlataforma, isNull);
      expect(BackendService.portaria.sapPlataforma, isNull);
    });
  });

  group('ContagemCegaRepositoryRouter', () {
    late FakeContagemCegaRepository s4hana;
    late FakeContagemCegaRepository ecc;
    late ContagemCegaRepositoryRouter router;

    setUp(() {
      s4hana = FakeContagemCegaRepository();
      ecc = FakeContagemCegaRepository();
      router = ContagemCegaRepositoryRouter(s4hana: s4hana, ecc: ecc);
    });

    test('Bandeirantes vai para o SEGW', () async {
      await router.carregarCheckin(
        backend: BackendService.sapBandeirantes,
        checkin: '0000000001',
      );
      expect(ecc.checkinsRecebidos, ['0000000001']);
      expect(s4hana.checkinsRecebidos, isEmpty);
    });

    for (final backend in [BackendService.sapNel, BackendService.sapVitamedic]) {
      test('${backend.name} continua no serviço CDS', () async {
        await router.carregarCheckin(backend: backend, checkin: '0000000002');
        expect(s4hana.checkinsRecebidos, ['0000000002']);
        expect(ecc.checkinsRecebidos, isEmpty);
      });
    }

    // O perfil funcional troca de empresa com a tela aberta. Se o router
    // guardasse a implementação da primeira chamada, a leitura seguinte iria
    // para o serviço da empresa anterior — e o conferente contaria a carga de
    // um SAP contra os dados de outro.
    test('o despacho é por chamada, não por sessão', () async {
      await router.carregarCheckin(
        backend: BackendService.sapBandeirantes,
        checkin: '0000000003',
      );
      await router.carregarCheckin(
        backend: BackendService.sapNel,
        checkin: '0000000004',
      );
      expect(ecc.checkinsRecebidos, ['0000000003']);
      expect(s4hana.checkinsRecebidos, ['0000000004']);
    });

    test('backend não-SAP é bug, não formato padrão', () {
      expect(
        () => router.carregarCheckin(
          backend: BackendService.core,
          checkin: '0000000005',
        ),
        throwsStateError,
      );
    });
  });

  group('ContagemCegaEccCampos', () {
    // A diferença que falha em silêncio: propriedade errada num `$filter`
    // devolve lista vazia, que a tela lê como "nunca foi contado" em vez de
    // erro. O import DDIC do SEGW capitaliza o que a CDS deixava minúsculo.
    test('o lote do ECC é NLote, e o do CDS é nLote', () {
      expect(ContagemCegaEccCampos.lote, 'NLote');
      expect(ContagemCegaCampos.lote, 'nLote');
      expect(ContagemCegaEccCampos.lote, isNot(ContagemCegaCampos.lote));
    });

    test('os entity sets da contagem não coincidem entre os dois', () {
      expect(ContagemCegaEccCampos.headerSet, 'IN100ContagemACega');
      expect(ContagemCegaEccCampos.logSet, 'IN100ContagemACegaLog');
      expect(
        ContagemCegaEccCampos.headerSet,
        isNot(ContagemCegaCampos.headerSet),
      );
      expect(ContagemCegaEccCampos.logSet, isNot(ContagemCegaCampos.logSet));
    });

    // No S/4HANA são dois serviços (as tabelas Z num, a finalização noutro); no
    // ECC tudo foi reconstruído com SEGW dentro do serviço genérico. Uma sessão
    // só — o SapSessionRepository cacheia por `host|serviço`.
    test('o ECC resolve tudo num serviço só', () {
      expect(ContagemCegaEccCampos.servico, 'sap/ZGJAAUTO_GENERIC_SRV');
    });

    test('o domínio de status do cabeçalho é o mesmo nos dois', () {
      expect(
        ContagemCegaEccCampos.statusCabecalho,
        ContagemCegaCampos.statusCabecalho,
      );
      expect(
        ContagemCegaEccCampos.statusFinalizadoConforme,
        ContagemCegaCampos.statusFinalizadoConforme,
      );
      expect(
        ContagemCegaEccCampos.statusFinalizadoDivergente,
        ContagemCegaCampos.statusFinalizadoDivergente,
      );
    });

    test('a escala da quantidade é a mesma nos dois serviços', () {
      expect(
        ContagemCegaEccCampos.casasQuantidade,
        ContagemCegaCampos.casasQuantidade,
      );
    });
  });
}
