import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../features/profile/domain/entities/graph_profile.dart';
import '../utils/utils.dart';
import 'microsoft_auth_config.dart';
import 'microsoft_auth_result.dart';
import 'token_storage.dart';

/// Cliente do Microsoft Graph para dados do usuário logado (foto + perfil).
///
/// O access token da sessão tem audience `api://<clientId>/access` (o backend
/// do Portal), então NÃO serve para chamar o Graph. Aqui trocamos o
/// `refresh_token` (obtido com `offline_access` no login) por um access token
/// com audience do Graph (`https://graph.microsoft.com`, scope `User.Read`) —
/// o Azure AD v2 permite redimir o mesmo refresh token para outro recurso.
///
/// Se a troca rotacionar o refresh token (comportamento do Azure em SPA),
/// persistimos o novo refresh token de volta preservando o access token da API,
/// para não invalidar a sessão do backend.
class GraphService {
  GraphService({TokenStorage? storage, http.Client? client})
      : _storage = storage ?? TokenStorage.instance,
        _client = client ?? http.Client();

  final TokenStorage _storage;
  final http.Client _client;

  /// Última falha (diagnóstico) — exibida na tela `/me` quando a foto não vem.
  String? lastError;

  static const String _graphBase = 'https://graph.microsoft.com/v1.0';

  /// Scopes do Graph. `offline_access` garante um refresh token de volta;
  /// `User.Read` autoriza `/me` e `/me/photo`.
  ///
  /// Para exibir a foto de OUTROS usuários ([fetchPhotoFor], ex.: colaboradores
  /// no BI), o token precisa de `User.Read.All`. Só adicione a linha abaixo
  /// DEPOIS de conceder consentimento admin dessa permissão no App Registration
  /// — pedir um scope não consentido faz a troca do refresh token falhar e
  /// quebra também a foto do `/me`. Sem ela, `/users/{id}/photo` responde 403 e
  /// o avatar cai nas iniciais (degradação graciosa).
  //   'https://graph.microsoft.com/User.Read.All',
  static const List<String> _graphScopes = [
    'openid',
    'profile',
    'offline_access',
    'https://graph.microsoft.com/User.Read',
  ];

  // Cache do token do Graph enquanto válido (evita redimir o refresh a cada call).
  String? _graphToken;
  DateTime? _graphTokenExpiry;

  /// Redime o refresh token da sessão por um access token com audience do Graph.
  /// Retorna `null` quando não há sessão/refresh token ou a troca falha (ex.:
  /// consentimento de `User.Read` ausente) — o chamador degrada graciosamente.
  Future<String?> _accessToken() async {
    final cached = _graphToken;
    final expiry = _graphTokenExpiry;
    if (cached != null && expiry != null && DateTime.now().isBefore(expiry)) {
      return cached;
    }

    final session = await _storage.read();
    final refreshToken = session?.refreshToken;
    if (session == null || refreshToken == null) {
      lastError = 'Sem sessão/refresh token para trocar por token do Graph.';
      return null;
    }

    try {
      final response = await _client.post(
        Uri.parse(MicrosoftAuthConfig.tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': MicrosoftAuthConfig.clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': _graphScopes.join(' '),
        },
      );
      if (response.statusCode != 200) {
        lastError = 'Token mint ${response.statusCode}: ${response.body}';
        AppLogger.warning('Graph token mint failed: ${response.body}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final token = json['access_token'] as String?;
      if (token == null) {
        lastError = 'Resposta do token sem access_token: ${response.body}';
        return null;
      }
      lastError = null;

      final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3300;
      _graphToken = token;
      // Margem de 60s para não usar o token no limite da expiração.
      _graphTokenExpiry =
          DateTime.now().add(Duration(seconds: expiresIn - 60));

      // Rotação de refresh token: persiste o novo preservando o access token da
      // API, senão o refresh antigo (agora inválido) quebraria a sessão. Uma
      // falha ao salvar não pode descartar o token do Graph já obtido.
      final rotated = json['refresh_token'] as String?;
      if (rotated != null && rotated != refreshToken) {
        try {
          await _storage.save(MicrosoftAuthResult(
            accessToken: session.accessToken,
            idToken: session.idToken,
            refreshToken: rotated,
            expiresAt: session.expiresAt,
            userId: session.userId,
            email: session.email,
            name: session.name,
          ));
        } catch (e) {
          AppLogger.warning('Graph refresh token persist failed: $e');
        }
      }

      return token;
    } catch (e) {
      lastError = 'Erro na troca de token: $e';
      AppLogger.warning('Graph token mint error: $e');
      return null;
    }
  }

  /// Bytes da foto do usuário logado (`GET /me/photo/\$value`). Retorna `null`
  /// quando o usuário não tem foto (404) ou a chamada falha.
  Future<Uint8List?> fetchMyPhoto() async {
    final token = await _accessToken();
    if (token == null) return null;
    try {
      final response = await _client.get(
        Uri.parse('$_graphBase/me/photo/\$value'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        lastError = null;
        return response.bodyBytes;
      }
      // Usuário sem foto: o Graph responde 404 com code "ImageNotFound". É um
      // caso esperado, não uma falha — não deve virar diagnóstico na tela.
      // Qualquer outro status/erro é falha real e continua sendo reportado.
      if (response.statusCode == 404 || _isImageNotFound(response.body)) {
        lastError = null;
        return null;
      }
      lastError = 'Foto ${response.statusCode}: ${response.body}';
      return null;
    } catch (e) {
      lastError = 'Erro ao buscar foto: $e';
      AppLogger.warning('Graph photo fetch error: $e');
      return null;
    }
  }

  /// Bytes da foto de um usuário específico (`GET /users/{idOrUpn}/photo/$value`),
  /// para exibir a foto de colaboradores (ex.: Performance Individual do BI).
  /// [idOrUpn] é o e-mail/UPN ou objectId do usuário no Azure AD.
  ///
  /// Retorna `null` — caindo nas iniciais — quando o colaborador não tem foto
  /// (404/`ImageNotFound`), quando falta a permissão de Graph (`User.Read.All`
  /// ainda não consentida → 403) ou em qualquer outra falha. Não reporta essas
  /// falhas via [lastError], para não poluir o diagnóstico da tela `/me`.
  Future<Uint8List?> fetchPhotoFor(String idOrUpn) async {
    if (idOrUpn.trim().isEmpty) return null;
    final token = await _accessToken();
    if (token == null) return null;
    try {
      final response = await _client.get(
        Uri.parse(
            '$_graphBase/users/${Uri.encodeComponent(idOrUpn)}/photo/\$value'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) return response.bodyBytes;
      // 404/ImageNotFound = sem foto; 403 = sem permissão (User.Read.All).
      // Só logamos falhas inesperadas — em todos os casos caímos nas iniciais.
      if (response.statusCode != 404 &&
          response.statusCode != 403 &&
          !_isImageNotFound(response.body)) {
        AppLogger.warning(
            'Graph user photo ${response.statusCode} ($idOrUpn): ${response.body}');
      }
      return null;
    } catch (e) {
      AppLogger.warning('Graph user photo fetch error ($idOrUpn): $e');
      return null;
    }
  }

  /// `true` quando o corpo é o erro "sem foto" do Graph (`code`:
  /// `ImageNotFound`) — caso esperado que não deve ser tratado como falha.
  bool _isImageNotFound(String body) {
    if (!body.contains('ImageNotFound')) return false;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'];
      return error is Map<String, dynamic> && error['code'] == 'ImageNotFound';
    } catch (_) {
      // Corpo não-JSON mas com o marcador: trata como sem foto mesmo assim.
      return true;
    }
  }

  /// Perfil do usuário logado (`GET /me`). Retorna `null` em falha.
  Future<GraphProfile?> fetchMyProfile() async {
    final token = await _accessToken();
    if (token == null) return null;
    try {
      final response = await _client.get(
        Uri.parse('$_graphBase/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        AppLogger.warning('Graph /me failed: ${response.statusCode}');
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return GraphProfile.fromJson(json);
    } catch (e) {
      AppLogger.warning('Graph /me error: $e');
      return null;
    }
  }
}
