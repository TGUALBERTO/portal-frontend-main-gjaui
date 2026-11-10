import 'dart:async';
import 'dart:convert';
// `dart:html` é seguro aqui: este arquivo só é compilado no alvo web via
// import condicional (ver microsoft_auth_service.dart). Em mobile/desktop o
// stub é usado no lugar, então `dart:html` nunca chega ao build nativo.
import 'dart:html' as html;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../utils/utils.dart';
import 'microsoft_auth_config.dart';
import 'microsoft_auth_result.dart';
import 'microsoft_auth_service.dart';

/// Fluxo OAuth2 + PKCE para web. Diferente do desktop (que sobe um
/// `HttpServer` local em `dart:io`, indisponível no navegador), abrimos um
/// popup para o endpoint de autorização e recebemos o `code` de volta via
/// `postMessage` da página de callback (`web/auth.html`). O token é trocado
/// por uma chamada HTTP direta — o endpoint de token do Azure só envia
/// cabeçalhos CORS quando o redirect URI está registrado como plataforma
/// "Single-page application (SPA)" no App Registration.
class MicrosoftAuthServiceWeb implements MicrosoftAuthService {
  /// Redirect registrado no Azure (plataforma SPA). Usa a origem atual para
  /// funcionar em qualquer porta (ex.: http://localhost:5000/auth.html).
  String get _redirectUri => '${html.window.location.origin}/auth.html';

  @override
  Future<MicrosoftAuthResult> signIn() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _deriveCodeChallenge(codeVerifier);
    final state = _randomString(24);
    final redirectUri = _redirectUri;

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

    final popup = html.window
        .open(authUrl.toString(), 'ms_auth', 'width=520,height=640');
    // ignore: unnecessary_null_comparison
    if (popup == null) {
      throw StateError(
          'Popup bloqueado pelo navegador. Permita popups para fazer login.');
    }

    final params = await _awaitCallback(popup);

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
    // Nada do lado do provedor; o caller limpa o armazenamento de token.
  }

  /// Aguarda o `postMessage` da página de callback (`auth.html`). Também
  /// detecta o usuário fechando o popup manualmente (cancelamento).
  Future<Map<String, String?>> _awaitCallback(html.WindowBase popup) async {
    final completer = Completer<Map<String, String?>>();
    late StreamSubscription<html.MessageEvent> sub;
    Timer? closedPoll;

    sub = html.window.onMessage.listen((event) {
      // Aceita só mensagens da própria origem (evita injeção cross-origin).
      if (event.origin != html.window.location.origin) return;
      final data = event.data;
      if (data is! Map || data['type'] != 'ms-auth-callback') return;
      if (!completer.isCompleted) {
        completer.complete({
          'code': data['code'] as String?,
          'state': data['state'] as String?,
          'error': data['error'] as String?,
          'error_description': data['error_description'] as String?,
        });
      }
    });

    closedPoll = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if ((popup.closed ?? false) && !completer.isCompleted) {
        completer.completeError(StateError('Login cancelado pelo usuário'));
      }
    });

    try {
      return await completer.future;
    } finally {
      await sub.cancel();
      closedPoll.cancel();
      try {
        popup.close();
      } catch (_) {}
    }
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
    final refreshToken = (json['refresh_token'] as String?) ?? fallbackRefresh;
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

  static String _generateCodeVerifier() {
    // PKCE: 43-128 chars. 72 bytes aleatórios -> 96 chars base64url.
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
