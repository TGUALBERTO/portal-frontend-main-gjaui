import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';

import 'microsoft_auth_result.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _key = 'ms_auth_session';

  final EncryptedSharedPreferences _prefs = EncryptedSharedPreferences();

  Future<void> save(MicrosoftAuthResult result) async {
    await _prefs.setString(_key, result.encode());
  }

  Future<MicrosoftAuthResult?> read() async {
    final raw = await _prefs.getString(_key);
    if (raw.isEmpty) return null;
    try {
      return MicrosoftAuthResult.decode(raw);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
