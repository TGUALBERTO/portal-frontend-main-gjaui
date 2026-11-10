import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_repository.dart';
import 'package:gjamobile/src/features/access/domain/entities/user_access.dart';
import 'package:gjamobile/src/features/access/domain/enums/empresas.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/enums/checkin_checkout_veiculo_mode.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/entities/checkin_motorista.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/repositories/inbound_repository.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/presentation/controllers/checkin_checkout_veiculo_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_checkin.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/sap_backend_resolver.dart';
import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/empresa_sap_field.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:result_dart/result_dart.dart';

import 'fakes/fake_contagem_cega.dart';

class _AccessRepository implements AccessRepository {
  _AccessRepository(this.group, this.empresa);
  final String group;
  final int? empresa;

  @override
  AsyncAppResult<UserAccess> fetchCurrent() async =>
      Success(UserAccess.fromJson({
        'user': const {'id': '1', 'email': 'teste@empresa.com'},
        'groups': [
          {'id': 'g1', 'name': group}
        ],
        'employeeLink': {'codigoEmpresa': empresa, 'matricula': 123},
      }));
}

class _ContagemRepository extends FakeContagemCegaRepository {
  final backends = <BackendService>[];

  @override
  AsyncAppResult<ContagemCheckin> carregarCheckin({
    required BackendService backend,
    required String checkin,
  }) {
    backends.add(backend);
    return super.carregarCheckin(backend: backend, checkin: checkin);
  }

  @override
  AsyncAppResult<bool> garantirCabecalhoContagem({
    required BackendService backend,
    required String checkin,
  }) {
    backends.add(backend);
    return super.garantirCabecalhoContagem(backend: backend, checkin: checkin);
  }
}

class _InboundRepository implements InboundRepository {
  final backends = <BackendService>[];

  @override
  AsyncAppResult<CheckinMotorista> getCheckin({
    required BackendService backend,
    required String checkin,
  }) async {
    backends.add(backend);
    return Success(
        CheckinMotorista.fromJson({'CHECKIN': checkin, 'STATUS': 'R'}));
  }

  @override
  AsyncAppResult<bool> checkIn(
      {required BackendService backend, required String checkin}) async {
    backends.add(backend);
    return const Success(true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final group in ['Consultor', 'Operador']) {
    testWidgets('consulta e liberação usam a empresa permitida para $group',
        (tester) async {
      final access = AccessController(repository: _AccessRepository(group, 1));
      await access.load();
      addTearDown(access.dispose);
      final repository = _InboundRepository();
      final controller = CheckinCheckoutVeiculoController(
        repository: repository,
        backends: AccessSapBackendResolver(access),
        access: access,
      )..init(CheckinCheckoutVeiculoMode.checkIn);
      addTearDown(controller.dispose);
      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      final context = tester.element(find.byType(SizedBox));
      controller.selecionarEmpresa(Empresa.nel);
      controller.checkinController.text = '3';
      await controller.buscarCheckin(context: context);
      await controller.liberar(context: context);
      expect(
          repository.backends,
          everyElement(group == 'Consultor'
              ? BackendService.sapNel
              : BackendService.sapBandeirantes));
      controller.selecionarEmpresa(Empresa.vitamedic);
      expect(controller.checkinSignal.value,
          group == 'Consultor' ? isNull : isNotNull);
      controller.novaOperacao();
      await tester.pump();
    });
  }

  testWidgets('campo de empresa cabe no coletor e lista somente empresas SAP',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
      width: 280,
      child: EmpresaSapField(
          empresa: Empresa.refrescosBandeirantes, onChanged: (_) {}),
    ))));
    expect(tester.takeException(), isNull);
    final field = tester.widget<DropdownButtonFormField<Empresa>>(
        find.byType(DropdownButtonFormField<Empresa>));
    expect(field.initialValue, Empresa.refrescosBandeirantes);
    await tester.tap(find.byType(DropdownButtonFormField<Empresa>));
    await tester.pumpAndSettle();
    expect(find.text(Empresa.vitamedic.razaoSocial), findsOneWidget);
    expect(find.text(Empresa.nel.razaoSocial), findsOneWidget);
    expect(find.text(Empresa.rembal.razaoSocial), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final group in ['Consultor', ' consultor ', 'ADMIN', 'Operador']) {
    test('empresa da contagem respeita grupo $group', () async {
      final access = AccessController(repository: _AccessRepository(group, 1));
      await access.load();
      addTearDown(access.dispose);
      final repository = _ContagemRepository();
      final controller = ContagemCegaController(
        repository: repository,
        backends: AccessSapBackendResolver(access),
        access: access,
      );
      addTearDown(controller.dispose);
      final consultor = group.trim().toLowerCase() == 'consultor';
      expect(controller.podeSelecionarEmpresa, consultor);
      controller.selecionarEmpresa(Empresa.vitamedic);
      expect(await controller.carregarCheckin('3'), isTrue);
      await controller.abrirNota(0);
      expect(
          repository.backends,
          everyElement(consultor
              ? BackendService.sapVitamedic
              : BackendService.sapBandeirantes));
      controller.selecionarEmpresa(Empresa.nel);
      expect(controller.checkinSignal.value, consultor ? isNull : '3');
      if (consultor) expect(controller.notasSignal.value, isEmpty);
    });
  }

  test('consultor sem empresa pode selecionar nas duas operações', () async {
    final access =
        AccessController(repository: _AccessRepository('Consultor', null));
    await access.load();
    addTearDown(access.dispose);
    final contagem = ContagemCegaController(
      repository: _ContagemRepository(),
      backends: AccessSapBackendResolver(access),
      access: access,
    );
    addTearDown(contagem.dispose);
    expect(await contagem.carregarCheckin('3'), isFalse);
    contagem.selecionarEmpresa(Empresa.nel);
    expect(await contagem.carregarCheckin('3'), isTrue);

    final veiculo = CheckinCheckoutVeiculoController(
      repository: _InboundRepository(),
      backends: AccessSapBackendResolver(access),
      access: access,
    )..init(CheckinCheckoutVeiculoMode.checkIn);
    addTearDown(veiculo.dispose);
    expect(veiculo.configErrorSignal.value, isNull);
    veiculo.selecionarEmpresa(Empresa.vitamedic);
    expect(veiculo.empresaSelecionada, Empresa.vitamedic);
  });
}
