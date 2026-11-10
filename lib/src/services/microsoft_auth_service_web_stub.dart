import 'microsoft_auth_result.dart';
import 'microsoft_auth_service.dart';

/// Stub usado em alvos não-web (mobile/desktop) para que `dart:html` da
/// implementação real (microsoft_auth_service_web.dart) não entre no build
/// nativo. Nunca é instanciado fora da web — a seleção em
/// [MicrosoftAuthService] é protegida por `PlatformInfo.isWeb`.
class MicrosoftAuthServiceWeb implements MicrosoftAuthService {
  @override
  Future<MicrosoftAuthResult> signIn() =>
      throw UnsupportedError('MicrosoftAuthServiceWeb só é suportado na web');

  @override
  Future<MicrosoftAuthResult?> refresh(String refreshToken) =>
      throw UnsupportedError('MicrosoftAuthServiceWeb só é suportado na web');

  @override
  Future<void> signOut() =>
      throw UnsupportedError('MicrosoftAuthServiceWeb só é suportado na web');
}
