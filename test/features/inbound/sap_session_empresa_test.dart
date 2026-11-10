import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/shared/data/sap_session_repository.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';

void main() {
  const host = 'https://sap.example';
  const service = 'ZGJAAUTO_GENERIC_SRV';
  late Dio dio;
  late SapSessionRepository repository;
  late List<RequestOptions> requests;
  String? sistemaResposta;

  setUp(() {
    requests = [];
    sistemaResposta = null;
    dio = Dio(BaseOptions(baseUrl: 'https://portal.example'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      final codigo = options.queryParameters['codigoEmpresa'];
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'sapSystem': sistemaResposta ??
              {1: 'BANDEIRANTES', 6: 'NEL', 15: 'VITAMEDIC'}[codigo],
          'baseUrl': host,
          'csrfToken': 'token-teste',
          'cookies': ['sessao=teste'],
          'expiresIn': 1800,
        },
      ));
    }));
    repository = SapSessionRepository(CoreDio(dio));
  });

  tearDown(() => dio.close(force: true));

  for (final entry in {
    BackendService.sapBandeirantes: 1,
    BackendService.sapNel: 6,
    BackendService.sapVitamedic: 15,
  }.entries) {
    test('abertura e renovação enviam empresa ${entry.value}', () async {
      await repository.ensure(
          backend: entry.key, baseUrl: host, service: service);
      await repository.ensure(
          backend: entry.key, baseUrl: host, service: service);
      expect(requests, hasLength(1));
      await repository.ensure(
        backend: entry.key,
        baseUrl: host,
        service: service,
        refresh: true,
      );
      expect(requests, hasLength(2));
      for (final request in requests) {
        expect(request.path, '/sap/session');
        expect(request.queryParameters, {
          'baseUrl': host,
          'service': service,
          'codigoEmpresa': entry.value,
        });
      }
    });
  }

  test('cache separa empresas mesmo quando o host coincide', () async {
    await repository.ensure(
        backend: BackendService.sapBandeirantes,
        baseUrl: host,
        service: service);
    final vitamedic = await repository.ensure(
        backend: BackendService.sapVitamedic, baseUrl: host, service: service);
    expect(requests, hasLength(2));
    expect(vitamedic.sapSystem, 'VITAMEDIC');
  });

  test('rejeita sessão emitida para empresa diferente da selecionada',
      () async {
    sistemaResposta = 'BANDEIRANTES';
    await expectLater(
      repository.ensure(
          backend: BackendService.sapVitamedic,
          baseUrl: host,
          service: service),
      throwsA(isA<ServerFailure>()),
    );
  });
}
