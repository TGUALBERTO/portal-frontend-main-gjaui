import 'package:flutter_appauth/flutter_appauth.dart';

import '../utils/utils.dart';
import 'microsoft_auth_config.dart';
import 'microsoft_auth_result.dart';
import 'microsoft_auth_service.dart';

class MicrosoftAuthServiceMobile implements MicrosoftAuthService {
  MicrosoftAuthServiceMobile({FlutterAppAuth? appAuth})
      : _appAuth = appAuth ?? const FlutterAppAuth();

  final FlutterAppAuth _appAuth;

  AuthorizationServiceConfiguration get _serviceConfig =>
      AuthorizationServiceConfiguration(
        authorizationEndpoint: MicrosoftAuthConfig.authorizationEndpoint,
        tokenEndpoint: MicrosoftAuthConfig.tokenEndpoint,
      );

  @override
  Future<MicrosoftAuthResult> signIn() async {
    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        MicrosoftAuthConfig.clientId,
        MicrosoftAuthConfig.redirectUriAndroid,
        serviceConfiguration: _serviceConfig,
        scopes: MicrosoftAuthConfig.scopes,
        promptValues: const ['select_account'],
      ),
    );

    return _mapResponse(
      accessToken: response.accessToken,
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiration: response.accessTokenExpirationDateTime,
    );
  }

  @override
  Future<MicrosoftAuthResult?> refresh(String refreshToken) async {
    try {
      final response = await _appAuth.token(
        TokenRequest(
          MicrosoftAuthConfig.clientId,
          MicrosoftAuthConfig.redirectUriAndroid,
          serviceConfiguration: _serviceConfig,
          refreshToken: refreshToken,
          scopes: MicrosoftAuthConfig.scopes,
        ),
      );
      return _mapResponse(
        accessToken: response.accessToken,
        idToken: response.idToken,
        refreshToken: response.refreshToken ?? refreshToken,
        expiration: response.accessTokenExpirationDateTime,
      );
    } catch (e) {
      AppLogger.warning('MS refresh failed: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    // flutter_appauth does not expose a revoke; clearing local storage is
    // handled by the caller. End-session could be wired via endSession() if
    // a post-logout redirect is configured in Azure.
  }

  MicrosoftAuthResult _mapResponse({
    String? accessToken,
    String? idToken,
    String? refreshToken,
    DateTime? expiration,
  }) {
    if (accessToken == null || idToken == null) {
      throw StateError('Microsoft auth response missing tokens');
    }
    final expiresAt =
        expiration ?? DateTime.now().add(const Duration(minutes: 55));
    return MicrosoftAuthResult.fromTokens(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }
}
