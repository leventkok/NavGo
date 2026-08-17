import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists blended session material from handshake/bind.
class AuthTokenStore {
  AuthTokenStore._();

  static const _storage = FlutterSecureStorage();

  static const _kToken = 'navgo_blended_token';
  static const _kChannel = 'navgo_channel_path';
  static const _kBarrier = 'navgo_barrier';
  static const _kHandshake = 'navgo_handshake_id';

  static Future<void> save({
    required String blendedToken,
    required String channelPath,
    required String barrier,
    required String handshakeId,
  }) async {
    await _storage.write(key: _kToken, value: blendedToken);
    await _storage.write(key: _kChannel, value: channelPath);
    await _storage.write(key: _kBarrier, value: barrier);
    await _storage.write(key: _kHandshake, value: handshakeId);
  }

  static Future<String?> readToken() => _storage.read(key: _kToken);

  static Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kChannel);
    await _storage.delete(key: _kBarrier);
    await _storage.delete(key: _kHandshake);
  }
}
