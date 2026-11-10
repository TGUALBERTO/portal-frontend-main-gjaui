import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../utils/utils.dart';
import 'microsoft_auth_config.dart';
import 'microsoft_auth_result.dart';
import 'microsoft_auth_service.dart';

class MicrosoftAuthServiceDesktop implements MicrosoftAuthService {
  static const _responseHtml = '''
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>gjamobile</title></head>
  <body style="font-family:system-ui,sans-serif;text-align:center;padding:4rem;">
    <h2>Autenticação concluída</h2>
    <p>Você já pode fechar esta aba e voltar para o aplicativo.</p>
  </body>
</html>
''';

  @override
  Future<MicrosoftAuthResult> signIn() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _deriveCodeChallenge(codeVerifier);
    final state = _randomString(24);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://localhost:${server.port}';

    final authUrl = Uri.parse(MicrosoftAuthConfig.authorizationEndpoint)
        .replace(queryParameters: {
      'client_id': MicrosoftAuthConfig.clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'response_mode': 'query',
      'scope': MicrosoftAuthConfig.scopes.join(' '),
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'prompt': 'select_account',
    });

    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      await server.close(force: true);
      throw StateError('Não foi possível abrir o navegador para autenticação');
    }

    try {
      final params = await _awaitCallback(server);
      if (params['state'] != state) {
        throw StateError('State mismatch on OAuth callback');
      }
      final error = params['error'];
      if (error != null) {
        throw StateError('Microsoft retornou erro: $error '
            '${params['error_description'] ?? ''}');
      }
      final code = params['code'];
      if (code == null) {
        throw StateError('Callback sem authorization code');
      }
      return _exchangeCode(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );
    } finally {
      await server.close(force: true);
    }
  }

  @override
  Future<MicrosoftAuthResult?> refresh(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(MicrosoftAuthConfig.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': MicrosoftAuthConfig.clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': MicrosoftAuthConfig.scopes.join(' '),
        },
      );
      if (response.statusCode != 200) {
        AppLogger.warning('MS refresh failed: ${response.body}');
        return null;
      }
      return _parseTokenResponse(response.body, fallbackRefresh: refreshToken);
    } catch (e) {
      AppLogger.warning('MS refresh error: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    // Nothing provider-side; caller clears token storage.
  }

  Future<MicrosoftAuthResult> _exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final response = await http.post(
      Uri.parse(MicrosoftAuthConfig.tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': MicrosoftAuthConfig.clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
        'scope': MicrosoftAuthConfig.scopes.join(' '),
      },
    );
    if (response.statusCode != 200) {
      throw StateError('Falha na troca de code por token: ${response.body}');
    }
    return _parseTokenResponse(response.body);
  }

  MicrosoftAuthResult _parseTokenResponse(String body,
      {String? fallbackRefresh}) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final accessToken = json['access_token'] as String?;
    final idToken = json['id_token'] as String?;
    final refreshToken =
        (json['refresh_token'] as String?) ?? fallbackRefresh;
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3300;
    if (accessToken == null || idToken == null) {
      throw StateError('Resposta de token sem access_token ou id_token');
    }
    return MicrosoftAuthResult.fromTokens(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  Future<Map<String, String>> _awaitCallback(HttpServer server) async {
    final request = await server.first;
    final params = request.uri.queryParameters;
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_responseHtml);
    await request.response.close();
    return params;
  }

  static String _generateCodeVerifier() {
    // PKCE spec: 43-128 chars. 72 random bytes -> 96 base64url chars.
    final rand = Random.secure();
    final bytes = List<int>.generate(72, (_) => rand.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _deriveCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
