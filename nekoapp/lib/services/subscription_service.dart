import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/vpn_profile.dart';

class SubscriptionService {
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<VpnProfile>> fetchProfiles(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'NekoBox/1.0',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch subscription: ${response.statusCode}');
      }

      final content = response.body;
      
      // Try to detect format and parse accordingly
      if (url.contains('clash') || content.contains('proxies:')) {
        return _parseClashSubscription(content);
      } else if (content.startsWith('vmess://') || content.startsWith('vless://')) {
        return _parseShareLinks(content);
      } else {
        // Try base64 decode
        try {
          final decoded = utf8.decode(base64Decode(content));
          return _parseShareLinks(decoded);
        } catch (e) {
          // Try as JSON
          return _parseJsonSubscription(content);
        }
      }
    } catch (e) {
      throw Exception('Failed to fetch subscription: $e');
    }
  }

  static List<VpnProfile> parseClashSubscription(String content) {
    final profiles = <VpnProfile>[];
    
    try {
      // Parse YAML-like Clash config
      final lines = content.split('\n');
      bool inProxiesSection = false;
      Map<String, dynamic>? currentProxy;
      
      for (final line in lines) {
        final trimmed = line.trim();
        
        if (trimmed == 'proxies:') {
          inProxiesSection = true;
          continue;
        }
        
        if (!inProxiesSection) continue;
        
        if (trimmed.startsWith('- name:')) {
          if (currentProxy != null) {
            final profile = _createProfileFromClashProxy(currentProxy);
            if (profile != null) profiles.add(profile);
          }
          currentProxy = {};
          currentProxy['name'] = trimmed.substring(7).trim().replaceAll('"', '');
        } else if (currentProxy != null && trimmed.contains(':')) {
          final parts = trimmed.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim().replaceAll('"', '');
            currentProxy[key] = value;
          }
        }
      }
      
      // Add last proxy
      if (currentProxy != null) {
        final profile = _createProfileFromClashProxy(currentProxy);
        if (profile != null) profiles.add(profile);
      }
      
    } catch (e) {
      throw Exception('Failed to parse Clash subscription: $e');
    }
    
    return profiles;
  }

  static VpnProfile? _createProfileFromClashProxy(Map<String, dynamic> proxy) {
    try {
      final name = proxy['name'] as String;
      final type = proxy['type'] as String;
      final server = proxy['server'] as String;
      final port = int.parse(proxy['port'].toString());
      
      VpnProtocol protocol;
      Map<String, dynamic> config = {};
      
      switch (type.toLowerCase()) {
        case 'ss':
          protocol = VpnProtocol.shadowsocks;
          config = {
            'method': proxy['cipher'] ?? 'aes-256-gcm',
            'password': proxy['password'],
          };
          break;
        case 'vmess':
          protocol = VpnProtocol.vmess;
          config = {
            'uuid': proxy['uuid'],
            'alterId': int.tryParse(proxy['alterId']?.toString() ?? '0') ?? 0,
            'security': proxy['security'] ?? 'auto',
          };
          break;
        case 'trojan':
          protocol = VpnProtocol.trojan;
          config = {
            'password': proxy['password'],
          };
          break;
        case 'vless':
          protocol = VpnProtocol.vless;
          config = {
            'uuid': proxy['uuid'],
            'flow': proxy['flow'] ?? '',
          };
          break;
        case 'socks5':
          protocol = VpnProtocol.socks;
          config = {
            'username': proxy['username'],
            'password': proxy['password'],
          };
          break;
        case 'http':
          protocol = VpnProtocol.http;
          config = {
            'username': proxy['username'],
            'password': proxy['password'],
          };
          break;
        default:
          return null;
      }
      
      return VpnProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString() + "," + name.hashCode.toString(),
        name: name,
        protocol: protocol,
        server: server,
        port: port,
        protocolSettings: config,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  static List<VpnProfile> parseShareLinks(String content) {
    final profiles = <VpnProfile>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      try {
        if (trimmed.startsWith('vmess://')) {
          final profile = _parseVmessLink(trimmed);
          if (profile != null) profiles.add(profile);
        } else if (trimmed.startsWith('vless://')) {
          final profile = _parseVlessLink(trimmed);
          if (profile != null) profiles.add(profile);
        } else if (trimmed.startsWith('trojan://')) {
          final profile = _parseTrojanLink(trimmed);
          if (profile != null) profiles.add(profile);
        } else if (trimmed.startsWith('ss://')) {
          final profile = _parseShadowsocksLink(trimmed);
          if (profile != null) profiles.add(profile);
        }
      } catch (e) {
        // Skip invalid links
        continue;
      }
    }
    
    return profiles;
  }

  static VpnProfile? _parseVmessLink(String link) {
    try {
      final base64Part = link.substring(8); // Remove 'vmess://'
      final decoded = utf8.decode(base64Decode(base64Part));
      final data = jsonDecode(decoded);
      
      return VpnProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_vmess',
        name: data['ps'] ?? 'VMess Server',
        protocol: VpnProtocol.vmess,
        server: data['add'],
        port: int.parse(data['port'].toString()),
        protocolSettings: {
          "uuid": data["id"],
          "alterId": int.tryParse(data["aid"]?.toString() ?? "0") ?? 0,
          "security": data["scy"] ?? "auto",
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  static VpnProfile? _parseVlessLink(String link) {
    try {
      final uri = Uri.parse(link);
      final params = uri.queryParameters;
      
      return VpnProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_vless',
        name: Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'VLESS Server'),
        protocol: VpnProtocol.vless,
        server: uri.host,
        port: uri.port,
        protocolSettings: {
          "uuid": uri.userInfo,
          "flow": params["flow"] ?? "",
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  static VpnProfile? _parseTrojanLink(String link) {
    try {
      final uri = Uri.parse(link);
      
      return VpnProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_trojan',
        name: Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'Trojan Server'),
        protocol: VpnProtocol.trojan,
        server: uri.host,
        port: uri.port,
        protocolSettings: {
          "password": uri.userInfo,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  static VpnProfile? _parseShadowsocksLink(String link) {
    try {
      final uri = Uri.parse(link);
      final userInfo = utf8.decode(base64Decode(uri.userInfo));
      final parts = userInfo.split(':');
      
      if (parts.length != 2) return null;
      
      return VpnProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_ss',
        name: Uri.decodeComponent(uri.fragment.isNotEmpty ? uri.fragment : 'Shadowsocks Server'),
        protocol: VpnProtocol.shadowsocks,
        server: uri.host,
        port: uri.port,
        protocolSettings: {
          "method": parts[0],
          "password": parts[1],
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  static List<VpnProfile> _parseJsonSubscription(String content) {
    try {
      final data = jsonDecode(content);
      
      if (data is List) {
        return data.map((item) => VpnProfile.fromJson(item)).toList();
      } else if (data is Map && data.containsKey('profiles')) {
        final profilesData = data['profiles'] as List;
        return profilesData.map((item) => VpnProfile.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to parse JSON subscription: $e');
    }
  }

  Future<bool> validateSubscriptionUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

