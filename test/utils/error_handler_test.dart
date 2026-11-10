import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/utils/error_handler.dart';
import 'package:gjamobile/src/utils/failure.dart';

DioException _erro(int status, dynamic data) {
  final request = RequestOptions(path: '/sap/opu/odata/sap/X/Y');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: request, statusCode: status, data: data),
  );
}

void main() {
  group('AppErrorHandler — erro OData V2 do SAP Gateway', () {
    test('JSON: usa message.value e o code', () {
      final failure = AppErrorHandler.mapError(_erro(500, {
        'error': {
          'code': 'ZIN/012',
          'message': {'lang': 'pt', 'value': 'Check-in 4 sem NF-e vinculada'},
        },
      }));

      expect(failure, isA<ApiFailure>());
      final api = failure as ApiFailure;
      expect(api.message, 'Check-in 4 sem NF-e vinculada');
      expect(api.status, 500);
      expect(api.code, 'ZIN/012');
    });

    test('JSON: acrescenta errordetails sem repetir a principal', () {
      final failure = AppErrorHandler.mapError(_erro(500, {
        'error': {
          'code': 'X',
          'message': {'lang': 'pt', 'value': 'Falha A'},
          'innererror': {
            'errordetails': [
              {'message': 'Falha A'},
              {'message': 'Falha B'},
            ],
          },
        },
      }));

      expect(failure.message, 'Falha A — Falha B');
    });

    test('XML: extrai o <message>', () {
      const xml = '<?xml version="1.0" encoding="utf-8"?>'
          '<error xmlns="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata">'
          '<code>SY/530</code><message xml:lang="pt">Tabela ZIN1008 vazia</message>'
          '</error>';

      expect(AppErrorHandler.mapError(_erro(500, xml)).message,
          'Tabela ZIN1008 vazia');
    });

    test('HTML: mostra só o título, não a página', () {
      const html = '<html><head><title>500 SAP Internal Server Error</title>'
          '</head><body>muito texto</body></html>';

      expect(AppErrorHandler.mapError(_erro(500, html)).message,
          'Erro 500: 500 SAP Internal Server Error');
    });

    test('sem corpo continua no fallback por status', () {
      expect(AppErrorHandler.mapError(_erro(500, null)).message,
          'Erro interno do servidor');
    });
  });
}
