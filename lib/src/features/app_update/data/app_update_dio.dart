import 'package:dio/dio.dart';

/// Marcador de DI para o [Dio] do canal de atualização, no mesmo espírito de
/// `CoreDio`/`TeamsbotDio` (`services/backend_dio.dart`): o `auto_injector`
/// resolve por tipo, e um `Dio` cru seria ambíguo.
///
/// Fica na feature, e não no registro de backends, porque o canal não é um
/// backend: é conteúdo estático do site de produção. Este [Dio] **não** leva o
/// interceptor de auth — o bearer do usuário não tem nada a fazer num pedido de
/// arquivo público.
class AppUpdateDio {
  const AppUpdateDio(this.dio);

  /// [Dio] sem interceptors.
  ///
  /// `receiveTimeout` no Dio é o tempo máximo **sem chegar dado**, não o total
  /// do download: um APK de 100 MB na rede da doca leva o que precisar, mas uma
  /// conexão muda cai em um minuto em vez de pendurar o diálogo.
  factory AppUpdateDio.create() => AppUpdateDio(
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
          ),
        ),
      );

  final Dio dio;
}
