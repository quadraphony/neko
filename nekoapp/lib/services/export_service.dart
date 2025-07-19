import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vpn_profile.dart';
import '../models/vpn_group.dart';
import 'encryption_service.dart';

class ExportService {
  /// Export profiles to napsternet format
  static Future<ExportResult> exportProfiles(
    List<VpnProfile> profiles, {
    String? password,
    String? customName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final profilesJson = profiles.map((p) => p.toJson()).toList();
      
      final exportData = EncryptionService.createNapsternetExport(
        profilesJson,
        password: password,
        metadata: metadata,
      );
      
      final filename = EncryptionService.generateExportFilename(
        customName: customName ?? 'profiles',
        encrypted: password != null && password.isNotEmpty,
      );
      
      final content = const JsonEncoder.withIndent('  ').convert(exportData);
      final file = await _saveToFile(content, filename);
      
      return ExportResult(
        file: file,
        filename: filename,
        content: content,
        encrypted: password != null && password.isNotEmpty,
        itemCount: profiles.length,
        type: ExportType.profiles,
      );
    } catch (e) {
      throw Exception('Failed to export profiles: $e');
    }
  }

  /// Export groups to napsternet format
  static Future<ExportResult> exportGroups(
    List<VpnGroup> groups, {
    String? password,
    String? customName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final groupsJson = groups.map((g) => g.toJson()).toList();
      
      final exportData = EncryptionService.createNapsternetExport(
        groupsJson,
        password: password,
        metadata: {
          ...?metadata,
          'export_type': 'groups',
        },
      );
      
      final filename = EncryptionService.generateExportFilename(
        customName: customName ?? 'groups',
        encrypted: password != null && password.isNotEmpty,
      );
      
      final content = const JsonEncoder.withIndent('  ').convert(exportData);
      final file = await _saveToFile(content, filename);
      
      return ExportResult(
        file: file,
        filename: filename,
        content: content,
        encrypted: password != null && password.isNotEmpty,
        itemCount: groups.length,
        type: ExportType.groups,
      );
    } catch (e) {
      throw Exception('Failed to export groups: $e');
    }
  }

  /// Export complete backup
  static Future<ExportResult> exportBackup(
    List<VpnProfile> profiles,
    List<VpnGroup> groups,
    Map<String, dynamic> settings, {
    String? password,
    String? customName,
  }) async {
    try {
      final backupData = <String, dynamic>{
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
        'settings': settings,
      };
      
      final exportData = EncryptionService.createNapsternetExport(
        backupData,
        password: password,
        metadata: {
          'export_type': 'backup',
          'profile_count': profiles.length,
          'group_count': groups.length,
        },
      );
      
      final filename = EncryptionService.generateExportFilename(
        customName: customName ?? 'backup',
        encrypted: password != null && password.isNotEmpty,
      );
      
      final content = const JsonEncoder.withIndent('  ').convert(exportData);
      final file = await _saveToFile(content, filename);
      
      return ExportResult(
        file: file,
        filename: filename,
        content: content,
        encrypted: password != null && password.isNotEmpty,
        itemCount: profiles.length + groups.length,
        type: ExportType.backup,
      );
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  /// Export single profile as share link
  static String exportProfileAsShareLink(VpnProfile profile) {
    try {
      switch (profile.protocol) {
        case VpnProtocol.vmess:
          return _generateVmessLink(profile);
        case VpnProtocol.vless:
          return _generateVlessLink(profile);
        case VpnProtocol.trojan:
          return _generateTrojanLink(profile);
        case VpnProtocol.shadowsocks:
          return _generateShadowsocksLink(profile);
        case VpnProtocol.socks:
          return _generateSocksLink(profile);
        case VpnProtocol.http:
          return _generateHttpLink(profile);
        default:
          throw Exception('Share link not supported for ${profile.protocol}');
      }
    } catch (e) {
      throw Exception('Failed to generate share link: $e');
    }
  }

  /// Export profiles as QR code data
  static Future<List<String>> exportProfilesAsQRData(List<VpnProfile> profiles) async {
    try {
      final qrData = <String>[];
      
      for (final profile in profiles) {
        try {
          final shareLink = exportProfileAsShareLink(profile);
          qrData.add(shareLink);
        } catch (e) {
          // Skip profiles that can't be converted to share links
          continue;
        }
      }
      
      return qrData;
    } catch (e) {
      throw Exception('Failed to generate QR data: $e');
    }
  }

  /// Share export file
  static Future<void> shareExportFile(ExportResult result) async {
    try {
      await Share.shareXFiles(
        [XFile(result.file.path)],
        text: 'NekoBox VPN Configuration - ${result.filename}',
        subject: 'VPN Configuration Export',
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  /// Share as text
  static Future<void> shareAsText(String content, String title) async {
    try {
      await Share.share(
        content,
        subject: title,
      );
    } catch (e) {
      throw Exception('Failed to share text: $e');
    }
  }

  /// Save content to file
  static Future<File> _saveToFile(String content, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      return file;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  /// Generate VMess share link
  static String _generateVmessLink(VpnProfile profile) {
    final vmessData = {
      "v": "2",
      "ps": profile.name,
      "add": profile.server,
      "port": profile.port.toString(),
      "id": profile.protocolSettings["uuid"],
      "aid": profile.protocolSettings["alterId"]?.toString() ?? "0",
      "scy": profile.protocolSettings["security"] ?? "auto",
      "net": "tcp",
      "type": "none",
      "host": "",
      "path": "",
      "tls": "",
      "sni": "",
    };
    
    final jsonString = jsonEncode(vmessData);
    final encoded = base64Encode(utf8.encode(jsonString));
    return "vmess://$encoded";
  }

  /// Generate VLESS share link
  static String _generateVlessLink(VpnProfile profile) {
    final uri = Uri(
      scheme: "vless",
      userInfo: profile.protocolSettings["uuid"],
      host: profile.server,
      port: profile.port,
      queryParameters: {
        "flow": profile.protocolSettings["flow"] ?? "",
        "security": "none",
        "type": "tcp",
      },
      fragment: Uri.encodeComponent(profile.name),
    );
    
    return uri.toString();
  }

  /// Generate Trojan share link
  static String _generateTrojanLink(VpnProfile profile) {
    final uri = Uri(
      scheme: "trojan",
      userInfo: profile.protocolSettings["password"],
      host: profile.server,
      port: profile.port,
      queryParameters: {
        "security": "tls",
        "type": "tcp",
      },
      fragment: Uri.encodeComponent(profile.name),
    );
    
    return uri.toString();
  }

  /// Generate Shadowsocks share link
  static String _generateShadowsocksLink(VpnProfile profile) {
    final method = profile.protocolSettings["method"];
    final password = profile.protocolSettings["password"];
    final userInfo = base64Encode(utf8.encode("$method:$password"));
    
    final uri = Uri(
      scheme: "ss",
      userInfo: userInfo,
      host: profile.server,
      port: profile.port,
      fragment: Uri.encodeComponent(profile.name),
    );
    
    return uri.toString();
  }

  /// Generate SOCKS share link
  static String _generateSocksLink(VpnProfile profile) {
    final username = profile.protocolSettings["username"] ?? "";
    final password = profile.protocolSettings["password"] ?? "";
    final userInfo = username.isNotEmpty ? "$username:$password" : "";
    
    final uri = Uri(
      scheme: "socks5",
      userInfo: userInfo.isNotEmpty ? userInfo : null,
      host: profile.server,
      port: profile.port,
      fragment: Uri.encodeComponent(profile.name),
    );
    
    return uri.toString();
  }

  /// Generate HTTP share link
  static String _generateHttpLink(VpnProfile profile) {
    final username = profile.protocolSettings["username"] ?? "";
    final password = profile.protocolSettings["password"] ?? "";
    final userInfo = username.isNotEmpty ? "$username:$password" : "";
    
    final uri = Uri(
      scheme: "http",
      userInfo: userInfo.isNotEmpty ? userInfo : null,
      host: profile.server,
      port: profile.port,
      fragment: Uri.encodeComponent(profile.name),
    );
    
    return uri.toString();
  }

  /// Get export statistics
  static ExportStatistics getExportStatistics(List<VpnProfile> profiles) {
    final protocolCounts = <VpnProtocol, int>{};
    
    for (final profile in profiles) {
      protocolCounts[profile.protocol] = (protocolCounts[profile.protocol] ?? 0) + 1;
    }
    
    return ExportStatistics(
      totalProfiles: profiles.length,
      protocolCounts: protocolCounts,
      supportedForShareLinks: profiles.where((p) => _supportsShareLink(p.protocol)).length,
    );
  }

  /// Check if protocol supports share links
  static bool _supportsShareLink(VpnProtocol protocol) {
    return [
      VpnProtocol.vmess,
      VpnProtocol.vless,
      VpnProtocol.trojan,
      VpnProtocol.shadowsocks,
      VpnProtocol.socks,
      VpnProtocol.http,
    ].contains(protocol);
  }
}

enum ExportType {
  profiles,
  groups,
  backup,
  shareLinks,
  qrCodes,
}

class ExportResult {
  final File file;
  final String filename;
  final String content;
  final bool encrypted;
  final int itemCount;
  final ExportType type;

  ExportResult({
    required this.file,
    required this.filename,
    required this.content,
    required this.encrypted,
    required this.itemCount,
    required this.type,
  });

  String get sizeFormatted {
    final bytes = content.length;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class ExportStatistics {
  final int totalProfiles;
  final Map<VpnProtocol, int> protocolCounts;
  final int supportedForShareLinks;

  ExportStatistics({
    required this.totalProfiles,
    required this.protocolCounts,
    required this.supportedForShareLinks,
  });
}

