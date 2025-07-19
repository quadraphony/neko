import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/vpn_profile.dart';
import 'subscription_service.dart';
import 'encryption_service.dart';

class ImportService {
  static final SubscriptionService _subscription = SubscriptionService();

  /// Import from clipboard
  static Future<ImportResult> importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        throw Exception('Clipboard is empty');
      }

      final content = clipboardData.text!.trim();
      return await _parseContent(content, source: 'Clipboard');
    } catch (e) {
      throw Exception('Failed to import from clipboard: $e');
    }
  }

  /// Import from QR code (placeholder for QR scanner integration)
  static Future<ImportResult> importFromQRCode(String qrContent) async {
    try {
      return await _parseContent(qrContent, source: 'QR Code');
    } catch (e) {
      throw Exception('Failed to import from QR code: $e');
    }
  }

  /// Import from file
  static Future<ImportResult> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt', 'conf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      
      return await _parseContent(content, source: 'File: ${result.files.first.name}');
    } catch (e) {
      throw Exception('Failed to import from file: $e');
    }
  }

  /// Import from URL
  static Future<ImportResult> importFromUrl(String url, {String? name}) async {
    try {
      final profiles = await _subscription.fetchProfiles(url);
      return ImportResult(
        profiles: profiles,
        groups: [],
        source: name != null ? 'URL: $name' : 'URL: $url',
        type: ImportType.subscription,
      );
    } catch (e) {
      throw Exception('Failed to import from URL: $e');
    }
  }

  /// Parse content and determine format
  static Future<ImportResult> _parseContent(String content, {required String source}) async {
    try {
      // Check if it's encrypted napsternet format
      if (EncryptionService.isValidEncryptedData(content)) {
        return await _parseEncryptedContent(content, source: source);
      }

      // Try to parse as JSON first
      try {
        final jsonData = jsonDecode(content);
        return await _parseJsonContent(jsonData, source: source);
      } catch (e) {
        // Not JSON, try other formats
      }

      // Check if it's a single share link
      if (_isSingleShareLink(content)) {
        final profiles = SubscriptionService.parseShareLinks(content);
        return ImportResult(
          profiles: profiles,
          groups: [],
          source: source,
          type: ImportType.shareLink,
        );
      }

      // Check if it's multiple share links
      if (_isMultipleShareLinks(content)) {
        final profiles = SubscriptionService.parseShareLinks(content);
        return ImportResult(
          profiles: profiles,
          groups: [],
          source: source,
          type: ImportType.shareLinks,
        );
      }

      // Check if it's Clash format
      if (_isClashFormat(content)) {
        final profiles = SubscriptionService.parseClashSubscription(content);
        return ImportResult(
          profiles: profiles,
          groups: [],
          source: source,
          type: ImportType.clash,
        );
      }

      // Try base64 decode
      try {
        final decoded = utf8.decode(base64Decode(content));
        return await _parseContent(decoded, source: source);
      } catch (e) {
        // Not base64
      }

      throw Exception('Unsupported format');
    } catch (e) {
      throw Exception('Failed to parse content: $e');
    }
  }

  /// Parse encrypted content
  static Future<ImportResult> _parseEncryptedContent(String content, {required String source}) async {
    // This would typically show a password dialog
    // For now, we'll try with default password
    try {
      final decrypted = EncryptionService.decryptData(content);
      final jsonData = jsonDecode(decrypted);
      return await _parseJsonContent(jsonData, source: source, encrypted: true);
    } catch (e) {
      throw Exception('Failed to decrypt content. Password may be required.');
    }
  }

  /// Parse JSON content
  static Future<ImportResult> _parseJsonContent(
    Map<String, dynamic> jsonData, 
    {required String source, bool encrypted = false}
  ) async {
    final type = jsonData['type'] as String?;
    
    switch (type) {
      case 'napsternet_config':
      case 'nekobox_profiles':
        return _parseNapsternetConfig(jsonData, source: source, encrypted: encrypted);
      
      case 'nekobox_groups':
        return _parseGroupsConfig(jsonData, source: source, encrypted: encrypted);
      
      case 'nekobox_backup':
        return _parseBackupConfig(jsonData, source: source, encrypted: encrypted);
      
      default:
        // Try to parse as generic profile list
        if (jsonData.containsKey('profiles')) {
          final profilesData = jsonData['profiles'] as List;
          final profiles = profilesData.map((p) => VpnProfile.fromJson(p)).toList();
          return ImportResult(
            profiles: profiles,
            groups: [],
            source: source,
            type: ImportType.profiles,
            encrypted: encrypted,
          );
        }
        
        throw Exception('Unknown JSON format');
    }
  }

  /// Parse napsternet config
  static ImportResult _parseNapsternetConfig(
    Map<String, dynamic> data, 
    {required String source, bool encrypted = false}
  ) {
    final profilesData = data['profiles'] as List;
    final profiles = profilesData.map((p) => VpnProfile.fromJson(p)).toList();
    
    return ImportResult(
      profiles: profiles,
      groups: [],
      source: source,
      type: ImportType.napsternet,
      encrypted: encrypted,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Parse groups config
  static ImportResult _parseGroupsConfig(
    Map<String, dynamic> data, 
    {required String source, bool encrypted = false}
  ) {
    final groupsData = data['groups'] as List;
    final groups = groupsData.map((g) => VpnGroup.fromJson(g)).toList();
    
    // Extract profiles from groups
    final profiles = <VpnProfile>[];
    for (final group in groups) {
      profiles.addAll(group.profiles);
    }
    
    return ImportResult(
      profiles: profiles,
      groups: groups,
      source: source,
      type: ImportType.groups,
      encrypted: encrypted,
    );
  }

  /// Parse backup config
  static ImportResult _parseBackupConfig(
    Map<String, dynamic> data, 
    {required String source, bool encrypted = false}
  ) {
    final profilesData = data['profiles'] as List;
    final groupsData = data['groups'] as List;
    
    final profiles = profilesData.map((p) => VpnProfile.fromJson(p)).toList();
    final groups = groupsData.map((g) => VpnGroup.fromJson(g)).toList();
    
    return ImportResult(
      profiles: profiles,
      groups: groups,
      source: source,
      type: ImportType.backup,
      encrypted: encrypted,
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  /// Check if content is a single share link
  static bool _isSingleShareLink(String content) {
    final trimmed = content.trim();
    return trimmed.startsWith('vmess://') ||
           trimmed.startsWith('vless://') ||
           trimmed.startsWith('trojan://') ||
           trimmed.startsWith('ss://') ||
           trimmed.startsWith('socks://') ||
           trimmed.startsWith('http://') ||
           trimmed.startsWith('https://');
  }

  /// Check if content contains multiple share links
  static bool _isMultipleShareLinks(String content) {
    final lines = content.split('\n');
    int linkCount = 0;
    
    for (final line in lines) {
      if (_isSingleShareLink(line.trim())) {
        linkCount++;
      }
    }
    
    return linkCount > 1;
  }

  /// Check if content is Clash format
  static bool _isClashFormat(String content) {
    return content.contains('proxies:') || 
           content.contains('proxy-groups:') ||
           content.contains('rules:');
  }

  /// Validate import content before processing
  static Future<bool> validateImportContent(String content) async {
    try {
      await _parseContent(content, source: 'Validation');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get import format info
  static Future<ImportFormatInfo> getImportFormatInfo(String content) async {
    try {
      if (EncryptionService.isValidEncryptedData(content)) {
        return ImportFormatInfo(
          format: 'Encrypted Napsternet',
          encrypted: true,
          requiresPassword: true,
        );
      }

      try {
        final jsonData = jsonDecode(content);
        final type = jsonData['type'] as String?;
        
        switch (type) {
          case 'napsternet_config':
            return ImportFormatInfo(format: 'Napsternet Config');
          case 'nekobox_profiles':
            return ImportFormatInfo(format: 'NekoBox Profiles');
          case 'nekobox_groups':
            return ImportFormatInfo(format: 'NekoBox Groups');
          case 'nekobox_backup':
            return ImportFormatInfo(format: 'NekoBox Backup');
          default:
            return ImportFormatInfo(format: 'Generic JSON');
        }
      } catch (e) {
        // Not JSON
      }

      if (_isSingleShareLink(content)) {
        return ImportFormatInfo(format: 'Share Link');
      }

      if (_isMultipleShareLinks(content)) {
        return ImportFormatInfo(format: 'Multiple Share Links');
      }

      if (_isClashFormat(content)) {
        return ImportFormatInfo(format: 'Clash Config');
      }

      return ImportFormatInfo(format: 'Unknown');
    } catch (e) {
      return ImportFormatInfo(format: 'Invalid');
    }
  }
}

enum ImportType {
  profiles,
  groups,
  backup,
  napsternet,
  shareLink,
  shareLinks,
  clash,
  subscription,
}

class ImportResult {
  final List<VpnProfile> profiles;
  final List<VpnGroup> groups;
  final String source;
  final ImportType type;
  final bool encrypted;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? settings;

  ImportResult({
    required this.profiles,
    required this.groups,
    required this.source,
    required this.type,
    this.encrypted = false,
    this.metadata,
    this.settings,
  });

  int get totalItems => profiles.length + groups.length;
  
  String get description {
    final items = <String>[];
    if (profiles.isNotEmpty) items.add('${profiles.length} profiles');
    if (groups.isNotEmpty) items.add('${groups.length} groups');
    return items.join(', ');
  }
}

class ImportFormatInfo {
  final String format;
  final bool encrypted;
  final bool requiresPassword;

  ImportFormatInfo({
    required this.format,
    this.encrypted = false,
    this.requiresPassword = false,
  });
}

