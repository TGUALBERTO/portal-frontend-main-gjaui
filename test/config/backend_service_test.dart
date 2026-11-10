import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/config/app_environment.dart';
import 'package:gjamobile/src/config/backend_service.dart';

void main() {
  group('BackendService.baseUrlFor', () {
    test('LOCAL do core é http://localhost:8080 (raiz, sem /api)', () {
      final url = BackendService.core.baseUrlFor(AppEnvironment.local);
      expect(url, 'http://localhost:8080');
      expect(url.contains('/api'), isFalse);
      expect(url.endsWith('/'), isFalse);
    });

    test('toda URL base é absoluta na raiz, sem /api e sem barra final', () {
      for (final service in BackendService.values) {
        for (final env in AppEnvironment.values) {
          final url = service.baseUrlFor(env);
          final uri = Uri.parse(url);
          expect(uri.hasScheme, isTrue, reason: url);
          expect(
            uri.scheme == 'http' || uri.scheme == 'https',
            isTrue,
            reason: url,
          );
          expect(uri.host, isNotEmpty, reason: url);
          // Raiz: sem path (ou só "/"), nunca /api. Checa o PATH (não a string
          // toda — "https://api-..." contém "/api" no "://api" sem ser path).
          expect(uri.path == '' || uri.path == '/', isTrue, reason: url);
          expect(uri.path.contains('/api'), isFalse, reason: url);
          expect(url.endsWith('/'), isFalse, reason: url);
        }
      }
    });
  });
}
