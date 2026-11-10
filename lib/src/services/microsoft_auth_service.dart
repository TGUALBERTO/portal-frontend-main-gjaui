import '../utils/utils.dart';
import 'microsoft_auth_result.dart';
import 'microsoft_auth_service_desktop.dart';
import 'microsoft_auth_service_mobile.dart';
// Import condicional: no build web usa a implementação real (dart:html); em
// mobile/desktop usa o stub, mantendo `dart:html` fora do build nativo.
import 'microsoft_auth_service_web_stub.dart'
    if (dart.library.js_interop) 'microsoft_auth_service_web.dart';

abstract class MicrosoftAuthService {
  static final MicrosoftAuthService instance = _resolve();

  static MicrosoftAuthService _resolve() {
    if (PlatformInfo.isWeb) {
      return MicrosoftAuthServiceWeb();
    }
    if (PlatformInfo.isAndroid || PlatformInfo.isIOS) {
      return MicrosoftAuthServiceMobile();
    }
    return MicrosoftAuthServiceDesktop();
  }

  /// Launches the interactive OAuth2 flow. Throws on cancel or error.
  Future<MicrosoftAuthResult> signIn();

  /// Refreshes an existing session using the given refresh token. Returns
  /// `null` if the refresh fails (e.g. token revoked/expired).
  Future<MicrosoftAuthResult?> refresh(String refreshToken);

  /// Clears any provider-side state (e.g. cached sessions on the broker).
  /// Token storage wipe is handled separately by the caller.
  Future<void> signOut();
}
