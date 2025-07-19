import 'dart:convert';

enum VpnProtocol {
  socks,
  http,
  ssh,
  shadowsocks,
  vmess,
  trojan,
  vless,
  anyTls,
  shadowTls,
  tuic,
  hysteria,
  hysteria2,
  wireguard,
  trojanGo,
  naiveProxy,
  mieru,
  naive,
  brook,
  snell
}

class VpnProfile {
  final String id;
  String name;
  VpnProtocol protocol;
  String server;
  int port;
  Map<String, dynamic> protocolSettings;
  String? username;
  String? password;
  String? group;
  String? remarks;
  bool isFavorite;
  String? groupId;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isActive;

  VpnProfile({
    required this.id,
    required this.name,
    required this.protocol,
    required this.server,
    required this.port,
    required this.protocolSettings,
    this.username,
    this.password,
    this.group,
    this.remarks,
    this.isFavorite = false,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = false,
  });

  factory VpnProfile.fromJson(Map<String, dynamic> json) {
    return VpnProfile(
      id: json["id"],
      name: json["name"],
      protocol: VpnProtocol.values.firstWhere(
        (e) => e.toString().split(".").last == json["protocol"],
      ),
      server: json["server"],
      port: json["port"],
      protocolSettings: Map<String, dynamic>.from(json["protocolSettings"] ?? {}),
      username: json["username"],
      password: json["password"],
      group: json["group"],
      remarks: json["remarks"],
      isFavorite: json["isFavorite"] ?? false,
      groupId: json["groupId"],
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
      isActive: json["isActive"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "protocol": protocol.toString().split(".").last,
      "server": server,
      "port": port,
      "protocolSettings": protocolSettings,
      "username": username,
      "password": password,
      "group": group,
      "remarks": remarks,
      "isFavorite": isFavorite,
      "groupId": groupId,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "isActive": isActive,
    };
  }

  String toSingBoxConfig() {
    final Map<String, dynamic> outbound = {
      "type": _getProtocolType(),
      "server": server,
      "server_port": port,
    };

    // Add protocol-specific configurations
    outbound.addAll(protocolSettings);

    return jsonEncode({
      "log": {
        "level": "info",
        "timestamp": true,
      },
      "inbounds": [
        {
          "type": "mixed",
          "listen": "127.0.0.1",
          "listen_port": 2080,
        }
      ],
      "outbounds": [outbound],
      "route": {
        "auto_detect_interface": true,
      }
    });
  }

  String _getProtocolType() {
    switch (protocol) {
      case VpnProtocol.socks:
        return "socks";
      case VpnProtocol.http:
        return "http";
      case VpnProtocol.ssh:
        return "ssh";
      case VpnProtocol.shadowsocks:
        return "shadowsocks";
      case VpnProtocol.vmess:
        return "vmess";
      case VpnProtocol.trojan:
        return "trojan";
      case VpnProtocol.vless:
        return "vless";
      case VpnProtocol.anyTls:
        return "anytls";
      case VpnProtocol.shadowTls:
        return "shadowtls";
      case VpnProtocol.tuic:
        return "tuic";
      case VpnProtocol.hysteria:
        return "hysteria";
      case VpnProtocol.hysteria2:
        return "hysteria2";
      case VpnProtocol.wireguard:
        return "wireguard";
      case VpnProtocol.trojanGo:
        return "trojan-go";
      case VpnProtocol.naiveProxy:
        return "naive";
      case VpnProtocol.mieru:
        return "mieru";
      case VpnProtocol.naive:
        return "naive";
      case VpnProtocol.brook:
        return "brook";
      case VpnProtocol.snell:
        return "snell";
    }
  }

  VpnProfile copyWith({
    String? id,
    String? name,
    VpnProtocol? protocol,
    String? server,
    int? port,
    Map<String, dynamic>? protocolSettings,
    String? username,
    String? password,
    String? group,
    String? remarks,
    bool? isFavorite,
    String? groupId,
    bool? isActive,
  }) {
    return VpnProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      server: server ?? this.server,
      port: port ?? this.port,
      protocolSettings: protocolSettings ?? this.protocolSettings,
      username: username ?? this.username,
      password: password ?? this.password,
      group: group ?? this.group,
      remarks: remarks ?? this.remarks,
      isFavorite: isFavorite ?? this.isFavorite,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }
}

class VpnGroup {
  final String id;
  final String name;
  final String? subscriptionUrl;
  final List<VpnProfile> profiles;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSubscription;

  VpnGroup({
    required this.id,
    required this.name,
    this.subscriptionUrl,
    required this.profiles,
    required this.createdAt,
    required this.updatedAt,
    this.isSubscription = false,
  });

  factory VpnGroup.fromJson(Map<String, dynamic> json) {
    return VpnGroup(
      id: json["id"],
      name: json["name"],
      subscriptionUrl: json["subscriptionUrl"],
      profiles: (json["profiles"] as List)
          .map((p) => VpnProfile.fromJson(p))
          .toList(),
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
      isSubscription: json["isSubscription"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "subscriptionUrl": subscriptionUrl,
      "profiles": profiles.map((p) => p.toJson()).toList(),
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "isSubscription": isSubscription,
    };
  }
}