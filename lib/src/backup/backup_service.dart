import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../storage/auren_database.dart';

class BackupService {
  BackupService(this._database);

  static const int formatVersion = 1;
  static const int schemaVersion = 1;
  static const String format = 'aurenbackup';
  static const String catalogEdition = 'strong-160';
  static const int _pbkdf2Iterations = 210000;

  final AurenDatabase _database;

  Future<String> exportEncrypted({required String passphrase}) async {
    _validatePassphrase(passphrase);

    final userData = await _database.exportUserData();
    final payload = jsonEncode({
      'format': format,
      'format_version': formatVersion,
      'schema_version': schemaVersion,
      'catalog_edition': catalogEdition,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'user_data': userData.toJson(),
    });

    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _deriveKey(passphrase, salt);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(payload),
      secretKey: secretKey,
      nonce: nonce,
    );

    return jsonEncode({
      'format': format,
      'format_version': formatVersion,
      'kdf': {
        'algorithm': 'pbkdf2-hmac-sha256',
        'iterations': _pbkdf2Iterations,
        'salt': base64Encode(salt),
      },
      'cipher': {
        'algorithm': 'aes-256-gcm',
        'nonce': base64Encode(box.nonce),
        'mac': base64Encode(box.mac.bytes),
        'ciphertext': base64Encode(box.cipherText),
      },
    });
  }

  Future<String> restoreEncrypted({
    required String encryptedBackup,
    required String passphrase,
  }) async {
    _validatePassphrase(passphrase);

    final rollback = await exportEncrypted(passphrase: passphrase);
    final payload = await _decryptPayload(encryptedBackup, passphrase);
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Backup payload is not valid.');
    }

    if (decoded['format'] != format ||
        decoded['format_version'] != formatVersion ||
        decoded['schema_version'] != schemaVersion ||
        decoded['catalog_edition'] != catalogEdition) {
      throw const FormatException(
        'Backup is not compatible with this AUREN build.',
      );
    }

    final rawUserData = decoded['user_data'];
    if (rawUserData is! Map<String, Object?>) {
      throw const FormatException('Backup does not contain user data.');
    }

    await _database.replaceUserData(AurenUserData.fromJson(rawUserData));
    return rollback;
  }

  Future<String> _decryptPayload(
    String encryptedBackup,
    String passphrase,
  ) async {
    try {
      final decoded = jsonDecode(encryptedBackup);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Backup envelope is not valid.');
      }
      if (decoded['format'] != format ||
          decoded['format_version'] != formatVersion) {
        throw const FormatException('Unsupported backup envelope.');
      }

      final kdf = decoded['kdf'];
      final cipher = decoded['cipher'];
      if (kdf is! Map || cipher is! Map) {
        throw const FormatException('Backup envelope is incomplete.');
      }

      final iterations = kdf['iterations'];
      if (iterations != _pbkdf2Iterations) {
        throw const FormatException(
          'Backup key derivation settings are unsupported.',
        );
      }

      final salt = base64Decode(kdf['salt'].toString());
      final nonce = base64Decode(cipher['nonce'].toString());
      final mac = base64Decode(cipher['mac'].toString());
      final cipherText = base64Decode(cipher['ciphertext'].toString());

      final secretKey = await _deriveKey(passphrase, salt);
      final clearText = await AesGcm.with256bits().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: secretKey,
      );
      return utf8.decode(clearText);
    } on SecretBoxAuthenticationError {
      throw const FormatException('Wrong passphrase or damaged backup.');
    }
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(passphrase)), nonce: salt);
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  void _validatePassphrase(String passphrase) {
    if (passphrase.trim().length < 8) {
      throw ArgumentError('Backup passphrase must be at least 8 characters.');
    }
  }
}
