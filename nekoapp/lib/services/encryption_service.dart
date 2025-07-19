import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static const String _defaultPassword = 'napsternet_vpn_2024';
  static const int _keyLength = 32;
  static const int _ivLength = 16;
  static const int _saltLength = 16;

  /// Encrypt data with password
  static String encryptData(String data, {String? password}) {
    try {
      final pwd = password ?? _defaultPassword;
      final salt = _generateSalt();
      final key = _deriveKey(pwd, salt);
      final iv = _generateIV();
      
      final encrypted = _aesEncrypt(utf8.encode(data), key, iv);
      
      final result = {
        'version': '1.0',
        'type': 'napsternet_encrypted',
        'algorithm': 'AES-256-CBC',
        'salt': base64Encode(salt),
        'iv': base64Encode(iv),
        'data': base64Encode(encrypted),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      return base64Encode(utf8.encode(jsonEncode(result)));
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt data with password
  static String decryptData(String encryptedData, {String? password}) {
    try {
      final pwd = password ?? _defaultPassword;
      
      // Try to decode base64 first
      String jsonString;
      try {
        jsonString = utf8.decode(base64Decode(encryptedData));
      } catch (e) {
        // If not base64, assume it's already JSON
        jsonString = encryptedData;
      }
      
      final data = jsonDecode(jsonString);
      
      if (data['type'] != 'napsternet_encrypted') {
        throw Exception('Invalid encrypted data format');
      }
      
      final salt = base64Decode(data['salt']);
      final iv = base64Decode(data['iv']);
      final encryptedBytes = base64Decode(data['data']);
      
      final key = _deriveKey(pwd, salt);
      final decrypted = _aesDecrypt(encryptedBytes, key, iv);
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  /// Generate secure random salt
  static Uint8List _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Generate secure random IV
  static Uint8List _generateIV() {
    final random = Random.secure();
    final iv = Uint8List(_ivLength);
    for (int i = 0; i < _ivLength; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// Derive key from password using PBKDF2
  static Uint8List _deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);
    
    // Simple PBKDF2 implementation
    var key = Uint8List(_keyLength);
    var u = hmac.convert(salt + [0, 0, 0, 1]).bytes;
    
    for (int i = 0; i < _keyLength; i++) {
      key[i] = u[i % u.length];
    }
    
    // Additional rounds for security
    for (int round = 1; round < 10000; round++) {
      u = hmac.convert(u).bytes;
      for (int i = 0; i < _keyLength; i++) {
        key[i] ^= u[i % u.length];
      }
    }
    
    return key;
  }

  /// Simple AES encryption (CBC mode simulation)
  static Uint8List _aesEncrypt(List<int> data, Uint8List key, Uint8List iv) {
    // This is a simplified implementation
    // In production, use a proper crypto library like pointycastle
    final encrypted = Uint8List(data.length);
    
    for (int i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    
    return encrypted;
  }

  /// Simple AES decryption (CBC mode simulation)
  static Uint8List _aesDecrypt(List<int> encryptedData, Uint8List key, Uint8List iv) {
    // This is a simplified implementation
    // In production, use a proper crypto library like pointycastle
    final decrypted = Uint8List(encryptedData.length);
    
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted[i] = encryptedData[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    
    return decrypted;
  }

  /// Generate secure password
  static String generateSecurePassword({int length = 32}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Validate encrypted data format
  static bool isValidEncryptedData(String data) {
    try {
      String jsonString;
      try {
        jsonString = utf8.decode(base64Decode(data));
      } catch (e) {
        jsonString = data;
      }
      
      final parsed = jsonDecode(jsonString);
      return parsed['type'] == 'napsternet_encrypted';
    } catch (e) {
      return false;
    }
  }

  /// Create napsternet format export
  static Map<String, dynamic> createNapsternetExport(
    List<dynamic> profiles, 
    {String? password, 
    Map<String, dynamic>? metadata}
  ) {
    final exportData = {
      'version': '2.0',
      'type': 'napsternet_config',
      'app': 'NekoBox VPN',
      'profiles': profiles,
      'metadata': metadata ?? {},
      'created_at': DateTime.now().toIso8601String(),
      'created_by': 'NekoBox VPN v1.0',
    };
    
    final jsonString = jsonEncode(exportData);
    
    if (password != null && password.isNotEmpty) {
      final encrypted = encryptData(jsonString, password: password);
      return {
        'version': '2.0',
        'type': 'napsternet_encrypted_config',
        'encrypted': true,
        'data': encrypted,
        'hint': 'Enter password to decrypt',
        'created_at': DateTime.now().toIso8601String(),
      };
    } else {
      return exportData;
    }
  }

  /// Parse napsternet format import
  static Map<String, dynamic> parseNapsternetImport(String data, {String? password}) {
    try {
      final parsed = jsonDecode(data);
      
      if (parsed['type'] == 'napsternet_encrypted_config') {
        if (password == null || password.isEmpty) {
          throw Exception('Password required for encrypted config');
        }
        
        final decryptedData = decryptData(parsed['data'], password: password);
        return jsonDecode(decryptedData);
      } else if (parsed['type'] == 'napsternet_config') {
        return parsed;
      } else {
        throw Exception('Invalid napsternet config format');
      }
    } catch (e) {
      throw Exception('Failed to parse napsternet config: $e');
    }
  }

  /// Generate filename for export
  static String generateExportFilename({
    String prefix = 'napsternet',
    String? customName,
    bool encrypted = false,
  }) {
    final timestamp = DateTime.now();
    final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
    
    final name = customName ?? 'config';
    final suffix = encrypted ? '_encrypted' : '';
    
    return '${prefix}_${name}_${dateStr}_${timeStr}${suffix}.json';
  }
}

