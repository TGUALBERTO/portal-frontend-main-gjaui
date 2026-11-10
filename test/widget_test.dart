import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/config/app_config.dart';
import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/data/repositories/inbound_repository_impl.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/repositories/inbound_repository.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/presentation/controllers/checkin_checkout_veiculo_controller.dart';

void main() {
  group('AppInjector', () {
    // AppInjector.setup() resolve os Dios por backend via AppConfig.dioFor,
    // que exige AppConfig.init() antes (mesma ordem do bootstrap em main, §3).
    // dioFor lança StateError se init não rodou. Hive não é preciso aqui:
    // HiveService.get é defensivo e o ambiente cai no fallback sem box aberta.
    setUpAll(() async {
      await AppConfig.init();
    });

    test('resolves SessionController as a singleton', () {
      AppInjector.setup();
      final a = AppInjector.get<SessionController>();
      final b = AppInjector.get<SessionController>();
      expect(identical(a, b), isTrue);
    });

    test('resolves AuthController on demand', () {
      AppInjector.setup();
      expect(AppInjector.get<AuthController>(), isA<AuthController>());
    });

    // A tela de check-in/out quebrava justamente por falta de registro. Este
    // teste percorre a cadeia inteira: os 3 Dios SAP -> SapSessionRepository ->
    // InboundRepositoryImpl -> controller (que ainda pede o AccessController).
    test('resolves InboundRepository against the abstract type', () {
      AppInjector.setup();
      expect(AppInjector.get<InboundRepository>(), isA<InboundRepositoryImpl>());
    });

    test('resolves CheckinCheckoutVeiculoController per screen', () {
      AppInjector.setup();
      final a = AppInjector.get<CheckinCheckoutVeiculoController>();
      final b = AppInjector.get<CheckinCheckoutVeiculoController>();
      expect(a, isA<CheckinCheckoutVeiculoController>());
      // Screen-scoped: factory, instância nova a cada get (a tela dá dispose).
      expect(identical(a, b), isFalse);
    });
  });
}
