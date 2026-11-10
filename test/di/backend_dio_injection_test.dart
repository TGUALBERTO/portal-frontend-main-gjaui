import 'package:auto_injector/auto_injector.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_repository.dart';
import 'package:gjamobile/src/features/auth/data/repositories/backend_user_repository.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/data/repositories/inbound_repository_impl.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/repositories/inbound_repository.dart';
import 'package:gjamobile/src/features/inbound/shared/data/sap_odata_client.dart';
import 'package:gjamobile/src/features/inbound/shared/data/sap_session_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/cadastros_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/estrutura_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/volume_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/caracteristicas_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/estrutura_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/parametros_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/volume_controller.dart';
import 'package:gjamobile/src/services/backend_dio.dart';

/// Smoke test do mecanismo de DI: o auto_injector resolve por TIPO, então os
/// repositórios core precisam receber o [CoreDio] (e não um [Dio] cru ambíguo).
/// Se o wrapper não satisfizesse o parâmetro do construtor, `get` lançaria.
void main() {
  test('repositórios core resolvem com CoreDio injetado', () {
    final injector = AutoInjector()
      ..addInstance<CoreDio>(CoreDio(Dio()))
      ..addLazySingleton<AccessRepository>(AccessRepository.new)
      ..addLazySingleton<AccessAdminRepository>(AccessAdminRepository.new)
      ..addLazySingleton<BackendUserRepository>(BackendUserRepository.new)
      ..commit();

    expect(injector.get<AccessRepository>(), isA<AccessRepository>());
    expect(injector.get<AccessAdminRepository>(), isA<AccessAdminRepository>());
    expect(injector.get<BackendUserRepository>(), isA<BackendUserRepository>());
  });

  /// A cadeia SAP tem 3 níveis (repositório -> cliente -> sessão) e 3 Dios
  /// marker-typed. Um construtor pedindo um tipo não registrado só estouraria em
  /// runtime, na primeira leitura de check-in — este teste antecipa isso.
  test('cadeia SAP resolve: repositório -> SapODataClient -> sessão', () {
    final injector = AutoInjector()
      ..addInstance<CoreDio>(CoreDio(Dio()))
      ..addInstance<SapBandeirantesDio>(SapBandeirantesDio(Dio()))
      ..addInstance<SapNelDio>(SapNelDio(Dio()))
      ..addInstance<SapVitamedicDio>(SapVitamedicDio(Dio()))
      ..addLazySingleton<SapSessionRepository>(SapSessionRepository.new)
      ..addLazySingleton<SapODataClient>(SapODataClient.new)
      ..addLazySingleton<InboundRepository>(InboundRepositoryImpl.new)
      ..commit();

    expect(injector.get<InboundRepository>(), isA<InboundRepositoryImpl>());

    // Singletons de verdade: o cache de sessão só serve para alguma coisa se
    // todos os repositórios SAP compartilharem a MESMA instância.
    expect(
      identical(injector.get<SapODataClient>(), injector.get<SapODataClient>()),
      isTrue,
    );
    expect(
      identical(
        injector.get<SapSessionRepository>(),
        injector.get<SapSessionRepository>(),
      ),
      isTrue,
    );
  });

  /// Os repositórios do RH Processo têm o parâmetro opcional `exigeRede` e
  /// por isso são registrados com fábrica, como no AppInjector.
  test('RH Processo: controllers resolvem com RhprocessoDio', () {
    final injector = AutoInjector();
    injector
      ..addInstance<RhprocessoDio>(RhprocessoDio(Dio()))
      ..addLazySingleton<VolumeRepository>(
          () => VolumeRepository(injector.get<RhprocessoDio>()))
      ..addLazySingleton<EstruturaRepository>(
          () => EstruturaRepository(injector.get<RhprocessoDio>()))
      ..addLazySingleton<CadastrosRepository>(
          () => CadastrosRepository(injector.get<RhprocessoDio>()))
      ..addLazySingleton<VolumeController>(
          () => VolumeController(repository: injector.get<VolumeRepository>()))
      ..addLazySingleton<EstruturaController>(EstruturaController.new)
      ..addLazySingleton<CaracteristicasController>(CaracteristicasController.new)
      ..addLazySingleton<ParametrosController>(ParametrosController.new)
      ..commit();

    expect(injector.get<VolumeController>(), isA<VolumeController>());
    expect(injector.get<EstruturaController>(), isA<EstruturaController>());
    expect(injector.get<CaracteristicasController>(), isA<CaracteristicasController>());
    expect(injector.get<ParametrosController>(), isA<ParametrosController>());
  });
}
