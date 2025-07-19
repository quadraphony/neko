import 'dart:convert';
import 'package:flutter/material.dart';

enum ServiceMode { vpn, proxy }
enum TunImplementation { mixed, system, gvisor }
enum DomainStrategy { auto, useIp, useIpv4, useIpv6, preferIpv4, preferIpv6 }
enum LogLevel { trace, debug, info, warn, error, fatal, panic }
enum Ipv6Route { disable, enable, prefer, only }

class AppSettings {
  // Core Settings
  final ServiceMode serviceMode;
  final TunImplementation tunImplementation;
  final int mtu;
  final int speedNotificationUpdateInterval;
  final bool profileTrafficStatistics;
  final bool showDirectSpeed;
  final bool showGroupNameInNotification;
  final bool alwaysShowAddress;
  final bool meteredHint;
  final bool acquireWakeLock;
  final LogLevel logLevel;

  // DNS Settings
  final DomainStrategy domainStrategyForServerAddress;
  final bool enableDnsRouting;
  final bool enableFakeDns;
  final String remoteDns;
  final DomainStrategy domainStrategyForRemote;
  final String directDns;

  // Inbound Settings
  final int proxyPort;
  final bool appendHttpProxyToVpn;
  final bool allowConnectionsFromLan;

  // Route Settings
  final bool appsVpnMode;
  final bool bypassLan;
  final bool bypassLanInCore;
  final bool enableTrafficSniffing;
  final bool resolveDestination;
  final Ipv6Route ipv6Route;
  final String ruleAssetsProvider;

  // Misc Settings
  final String connectionTestUrl;
  final bool enableClashApi;
  final String clashApiPort;

  // Advanced Settings
  final bool autoConnect;
  final bool autoReconnect;
  final bool killSwitch;
  final bool systemProxy;
  final bool ipv6Support;
  final int connectionTimeout;
  final int reconnectDelay;
  final List<String> dnsServers;
  final bool dohEnabled;
  final bool adBlockEnabled;
  final bool malwareProtectionEnabled;
  final bool leakProtectionEnabled;
  final bool webrtcLeakProtectionEnabled;
  final bool userAgentRandomizationEnabled;
  final String encryptionLevel;
  final bool connectionPoolingEnabled;
  final bool multiplexingEnabled;
  final bool dataCompressionEnabled;
  final int maxConnections;
  final String congestionControl;
  final bool speedTestEnabled;
  final bool trafficMonitoringEnabled;
  final bool bandwidthLimitEnabled;
  final int uploadSpeedLimit;
  final int downloadSpeedLimit;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool systemTrayEnabled;
  final String language;
  final List<String> routingRules;
  final List<String> bypassList;

  const AppSettings({
    // Core Settings
    this.serviceMode = ServiceMode.vpn,
    this.tunImplementation = TunImplementation.mixed,
    this.mtu = 9000,
    this.speedNotificationUpdateInterval = 1,
    this.profileTrafficStatistics = true,
    this.showDirectSpeed = true,
    this.showGroupNameInNotification = false,
    this.alwaysShowAddress = false,
    this.meteredHint = false,
    this.acquireWakeLock = false,
    this.logLevel = LogLevel.info,

    // DNS Settings
    this.domainStrategyForServerAddress = DomainStrategy.auto,
    this.enableDnsRouting = true,
    this.enableFakeDns = false,
    this.remoteDns = 'https://dns.google/dns-query',
    this.domainStrategyForRemote = DomainStrategy.auto,
    this.directDns = 'https://223.5.5.5/dns-query',

    // Inbound Settings
    this.proxyPort = 2080,
    this.appendHttpProxyToVpn = false,
    this.allowConnectionsFromLan = false,

    // Route Settings
    this.appsVpnMode = false,
    this.bypassLan = false,
    this.bypassLanInCore = false,
    this.enableTrafficSniffing = true,
    this.resolveDestination = true,
    this.ipv6Route = Ipv6Route.disable,
    this.ruleAssetsProvider = 'Official',

    // Misc Settings
    this.connectionTestUrl = 'http://cp.cloudflare.com/',
    this.enableClashApi = false,
    this.clashApiPort = '9090',

    // Advanced Settings
    this.autoConnect = false,
    this.autoReconnect = true,
    this.killSwitch = false,
    this.systemProxy = true,
    this.ipv6Support = false,
    this.connectionTimeout = 30,
    this.reconnectDelay = 5,
    this.dnsServers = const ['8.8.8.8', '8.8.4.4'],
    this.dohEnabled = false,
    this.adBlockEnabled = false,
    this.malwareProtectionEnabled = false,
    this.leakProtectionEnabled = true,
    this.webrtcLeakProtectionEnabled = true,
    this.userAgentRandomizationEnabled = false,
    this.encryptionLevel = 'high',
    this.connectionPoolingEnabled = true,
    this.multiplexingEnabled = true,
    this.dataCompressionEnabled = false,
    this.maxConnections = 100,
    this.congestionControl = 'bbr',
    this.speedTestEnabled = true,
    this.trafficMonitoringEnabled = true,
    this.bandwidthLimitEnabled = false,
    this.uploadSpeedLimit = 0,
    this.downloadSpeedLimit = 0,
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.systemTrayEnabled = true,
    this.language = 'en',
    this.routingRules = const [],
    this.bypassList = const [],
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      // Core Settings
      serviceMode: ServiceMode.values.firstWhere(
        (e) => e.toString().split('.').last == json['serviceMode'],
        orElse: () => ServiceMode.vpn,
      ),
      tunImplementation: TunImplementation.values.firstWhere(
        (e) => e.toString().split('.').last == json['tunImplementation'],
        orElse: () => TunImplementation.mixed,
      ),
      mtu: json['mtu'] ?? 9000,
      speedNotificationUpdateInterval: json['speedNotificationUpdateInterval'] ?? 1,
      profileTrafficStatistics: json['profileTrafficStatistics'] ?? true,
      showDirectSpeed: json['showDirectSpeed'] ?? true,
      showGroupNameInNotification: json['showGroupNameInNotification'] ?? false,
      alwaysShowAddress: json['alwaysShowAddress'] ?? false,
      meteredHint: json['meteredHint'] ?? false,
      acquireWakeLock: json['acquireWakeLock'] ?? false,
      logLevel: LogLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['logLevel'],
        orElse: () => LogLevel.info,
      ),

      // DNS Settings
      domainStrategyForServerAddress: DomainStrategy.values.firstWhere(
        (e) => e.toString().split('.').last == json['domainStrategyForServerAddress'],
        orElse: () => DomainStrategy.auto,
      ),
      enableDnsRouting: json['enableDnsRouting'] ?? true,
      enableFakeDns: json['enableFakeDns'] ?? false,
      remoteDns: json['remoteDns'] ?? 'https://dns.google/dns-query',
      domainStrategyForRemote: DomainStrategy.values.firstWhere(
        (e) => e.toString().split('.').last == json['domainStrategyForRemote'],
        orElse: () => DomainStrategy.auto,
      ),
      directDns: json['directDns'] ?? 'https://223.5.5.5/dns-query',

      // Inbound Settings
      proxyPort: json['proxyPort'] ?? 2080,
      appendHttpProxyToVpn: json['appendHttpProxyToVpn'] ?? false,
      allowConnectionsFromLan: json['allowConnectionsFromLan'] ?? false,

      // Route Settings
      appsVpnMode: json['appsVpnMode'] ?? false,
      bypassLan: json['bypassLan'] ?? false,
      bypassLanInCore: json['bypassLanInCore'] ?? false,
      enableTrafficSniffing: json['enableTrafficSniffing'] ?? true,
      resolveDestination: json['resolveDestination'] ?? true,
      ipv6Route: Ipv6Route.values.firstWhere(
        (e) => e.toString().split('.').last == json['ipv6Route'],
        orElse: () => Ipv6Route.disable,
      ),
      ruleAssetsProvider: json['ruleAssetsProvider'] ?? 'Official',

      // Misc Settings
      connectionTestUrl: json['connectionTestUrl'] ?? 'http://cp.cloudflare.com/',
      enableClashApi: json['enableClashApi'] ?? false,
      clashApiPort: json['clashApiPort'] ?? '9090',

      // Advanced Settings
      autoConnect: json['autoConnect'] ?? false,
      autoReconnect: json['autoReconnect'] ?? true,
      killSwitch: json['killSwitch'] ?? false,
      systemProxy: json['systemProxy'] ?? true,
      ipv6Support: json['ipv6Support'] ?? false,
      connectionTimeout: json['connectionTimeout'] ?? 30,
      reconnectDelay: json['reconnectDelay'] ?? 5,
      dnsServers: List<String>.from(json['dnsServers'] ?? ['8.8.8.8', '8.8.4.4']),
      dohEnabled: json['dohEnabled'] ?? false,
      adBlockEnabled: json['adBlockEnabled'] ?? false,
      malwareProtectionEnabled: json['malwareProtectionEnabled'] ?? false,
      leakProtectionEnabled: json['leakProtectionEnabled'] ?? true,
      webrtcLeakProtectionEnabled: json['webrtcLeakProtectionEnabled'] ?? true,
      userAgentRandomizationEnabled: json['userAgentRandomizationEnabled'] ?? false,
      encryptionLevel: json['encryptionLevel'] ?? 'high',
      connectionPoolingEnabled: json['connectionPoolingEnabled'] ?? true,
      multiplexingEnabled: json['multiplexingEnabled'] ?? true,
      dataCompressionEnabled: json['dataCompressionEnabled'] ?? false,
      maxConnections: json['maxConnections'] ?? 100,
      congestionControl: json['congestionControl'] ?? 'bbr',
      speedTestEnabled: json['speedTestEnabled'] ?? true,
      trafficMonitoringEnabled: json['trafficMonitoringEnabled'] ?? true,
      bandwidthLimitEnabled: json['bandwidthLimitEnabled'] ?? false,
      uploadSpeedLimit: json['uploadSpeedLimit'] ?? 0,
      downloadSpeedLimit: json['downloadSpeedLimit'] ?? 0,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.toString().split(".").last == json["themeMode"],
        orElse: () => ThemeMode.system,
      ),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      systemTrayEnabled: json['systemTrayEnabled'] ?? true,
      language: json['language'] ?? 'en',
      routingRules: List<String>.from(json['routingRules'] ?? []),
      bypassList: List<String>.from(json['bypassList'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Core Settings
      'serviceMode': serviceMode.toString().split('.').last,
      'tunImplementation': tunImplementation.toString().split('.').last,
      'mtu': mtu,
      'speedNotificationUpdateInterval': speedNotificationUpdateInterval,
      'profileTrafficStatistics': profileTrafficStatistics,
      'showDirectSpeed': showDirectSpeed,
      'showGroupNameInNotification': showGroupNameInNotification,
      'alwaysShowAddress': alwaysShowAddress,
      'meteredHint': meteredHint,
      'acquireWakeLock': acquireWakeLock,
      'logLevel': logLevel.toString().split('.').last,

      // DNS Settings
      'domainStrategyForServerAddress': domainStrategyForServerAddress.toString().split('.').last,
      'enableDnsRouting': enableDnsRouting,
      'enableFakeDns': enableFakeDns,
      'remoteDns': remoteDns,
      'domainStrategyForRemote': domainStrategyForRemote.toString().split('.').last,
      'directDns': directDns,

      // Inbound Settings
      'proxyPort': proxyPort,
      'appendHttpProxyToVpn': appendHttpProxyToVpn,
      'allowConnectionsFromLan': allowConnectionsFromLan,

      // Route Settings
      'appsVpnMode': appsVpnMode,
      'bypassLan': bypassLan,
      'bypassLanInCore': bypassLanInCore,
      'enableTrafficSniffing': enableTrafficSniffing,
      'resolveDestination': resolveDestination,
      'ipv6Route': ipv6Route.toString().split('.').last,
      'ruleAssetsProvider': ruleAssetsProvider,

      // Misc Settings
      'connectionTestUrl': connectionTestUrl,
      'enableClashApi': enableClashApi,
      'clashApiPort': clashApiPort,

      // Advanced Settings
      'autoConnect': autoConnect,
      'autoReconnect': autoReconnect,
      'killSwitch': killSwitch,
      'systemProxy': systemProxy,
      'ipv6Support': ipv6Support,
      'connectionTimeout': connectionTimeout,
      'reconnectDelay': reconnectDelay,
      'dnsServers': dnsServers,
      'dohEnabled': dohEnabled,
      'adBlockEnabled': adBlockEnabled,
      'malwareProtectionEnabled': malwareProtectionEnabled,
      'leakProtectionEnabled': leakProtectionEnabled,
      'webrtcLeakProtectionEnabled': webrtcLeakProtectionEnabled,
      'userAgentRandomizationEnabled': userAgentRandomizationEnabled,
      'encryptionLevel': encryptionLevel,
      'connectionPoolingEnabled': connectionPoolingEnabled,
      'multiplexingEnabled': multiplexingEnabled,
      'dataCompressionEnabled': dataCompressionEnabled,
      'maxConnections': maxConnections,
      'congestionControl': congestionControl,
      'speedTestEnabled': speedTestEnabled,
      'trafficMonitoringEnabled': trafficMonitoringEnabled,
      'bandwidthLimitEnabled': bandwidthLimitEnabled,
      'uploadSpeedLimit': uploadSpeedLimit,
      'downloadSpeedLimit': downloadSpeedLimit,
      'themeMode': themeMode.toString().split('.').last,
      'notificationsEnabled': notificationsEnabled,
      'systemTrayEnabled': systemTrayEnabled,
      'language': language,
      'routingRules': routingRules,
      'bypassList': bypassList,
    };
  }

  AppSettings copyWith({
    ServiceMode? serviceMode,
    TunImplementation? tunImplementation,
    int? mtu,
    int? speedNotificationUpdateInterval,
    bool? profileTrafficStatistics,
    bool? showDirectSpeed,
    bool? showGroupNameInNotification,
    bool? alwaysShowAddress,
    bool? meteredHint,
    bool? acquireWakeLock,
    LogLevel? logLevel,
    DomainStrategy? domainStrategyForServerAddress,
    bool? enableDnsRouting,
    bool? enableFakeDns,
    String? remoteDns,
    DomainStrategy? domainStrategyForRemote,
    String? directDns,
    int? proxyPort,
    bool? appendHttpProxyToVpn,
    bool? allowConnectionsFromLan,
    bool? appsVpnMode,
    bool? bypassLan,
    bool? bypassLanInCore,
    bool? enableTrafficSniffing,
    bool? resolveDestination,
    Ipv6Route? ipv6Route,
    String? ruleAssetsProvider,
    String? connectionTestUrl,
    bool? enableClashApi,
    String? clashApiPort,
    bool? autoConnect,
    bool? autoReconnect,
    bool? killSwitch,
    bool? systemProxy,
    bool? ipv6Support,
    int? connectionTimeout,
    int? reconnectDelay,
    List<String>? dnsServers,
    bool? dohEnabled,
    bool? adBlockEnabled,
    bool? malwareProtectionEnabled,
    bool? leakProtectionEnabled,
    bool? webrtcLeakProtectionEnabled,
    bool? userAgentRandomizationEnabled,
    String? encryptionLevel,
    bool? connectionPoolingEnabled,
    bool? multiplexingEnabled,
    bool? dataCompressionEnabled,
    int? maxConnections,
    String? congestionControl,
    bool? speedTestEnabled,
    bool? trafficMonitoringEnabled,
    bool? bandwidthLimitEnabled,
    int? uploadSpeedLimit,
    int? downloadSpeedLimit,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? systemTrayEnabled,
    String? language,
    List<String>? routingRules,
    List<String>? bypassList,
  }) {
    return AppSettings(
      serviceMode: serviceMode ?? this.serviceMode,
      tunImplementation: tunImplementation ?? this.tunImplementation,
      mtu: mtu ?? this.mtu,
      speedNotificationUpdateInterval: speedNotificationUpdateInterval ?? this.speedNotificationUpdateInterval,
      profileTrafficStatistics: profileTrafficStatistics ?? this.profileTrafficStatistics,
      showDirectSpeed: showDirectSpeed ?? this.showDirectSpeed,
      showGroupNameInNotification: showGroupNameInNotification ?? this.showGroupNameInNotification,
      alwaysShowAddress: alwaysShowAddress ?? this.alwaysShowAddress,
      meteredHint: meteredHint ?? this.meteredHint,
      acquireWakeLock: acquireWakeLock ?? this.acquireWakeLock,
      logLevel: logLevel ?? this.logLevel,
      domainStrategyForServerAddress: domainStrategyForServerAddress ?? this.domainStrategyForServerAddress,
      enableDnsRouting: enableDnsRouting ?? this.enableDnsRouting,
      enableFakeDns: enableFakeDns ?? this.enableFakeDns,
      remoteDns: remoteDns ?? this.remoteDns,
      domainStrategyForRemote: domainStrategyForRemote ?? this.domainStrategyForRemote,
      directDns: directDns ?? this.directDns,
      proxyPort: proxyPort ?? this.proxyPort,
      appendHttpProxyToVpn: appendHttpProxyToVpn ?? this.appendHttpProxyToVpn,
      allowConnectionsFromLan: allowConnectionsFromLan ?? this.allowConnectionsFromLan,
      appsVpnMode: appsVpnMode ?? this.appsVpnMode,
      bypassLan: bypassLan ?? this.bypassLan,
      bypassLanInCore: bypassLanInCore ?? this.bypassLanInCore,
      enableTrafficSniffing: enableTrafficSniffing ?? this.enableTrafficSniffing,
      resolveDestination: resolveDestination ?? this.resolveDestination,
      ipv6Route: ipv6Route ?? this.ipv6Route,
      ruleAssetsProvider: ruleAssetsProvider ?? this.ruleAssetsProvider,
      connectionTestUrl: connectionTestUrl ?? this.connectionTestUrl,
      enableClashApi: enableClashApi ?? this.enableClashApi,
      clashApiPort: clashApiPort ?? this.clashApiPort,
      autoConnect: autoConnect ?? this.autoConnect,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      killSwitch: killSwitch ?? this.killSwitch,
      systemProxy: systemProxy ?? this.systemProxy,
      ipv6Support: ipv6Support ?? this.ipv6Support,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      reconnectDelay: reconnectDelay ?? this.reconnectDelay,
      dnsServers: dnsServers ?? this.dnsServers,
      dohEnabled: dohEnabled ?? this.dohEnabled,
      adBlockEnabled: adBlockEnabled ?? this.adBlockEnabled,
      malwareProtectionEnabled: malwareProtectionEnabled ?? this.malwareProtectionEnabled,
      leakProtectionEnabled: leakProtectionEnabled ?? this.leakProtectionEnabled,
      webrtcLeakProtectionEnabled: webrtcLeakProtectionEnabled ?? this.webrtcLeakProtectionEnabled,
      userAgentRandomizationEnabled: userAgentRandomizationEnabled ?? this.userAgentRandomizationEnabled,
      encryptionLevel: encryptionLevel ?? this.encryptionLevel,
      connectionPoolingEnabled: connectionPoolingEnabled ?? this.connectionPoolingEnabled,
      multiplexingEnabled: multiplexingEnabled ?? this.multiplexingEnabled,
      dataCompressionEnabled: dataCompressionEnabled ?? this.dataCompressionEnabled,
      maxConnections: maxConnections ?? this.maxConnections,
      congestionControl: congestionControl ?? this.congestionControl,
      speedTestEnabled: speedTestEnabled ?? this.speedTestEnabled,
      trafficMonitoringEnabled: trafficMonitoringEnabled ?? this.trafficMonitoringEnabled,
      bandwidthLimitEnabled: bandwidthLimitEnabled ?? this.bandwidthLimitEnabled,
      uploadSpeedLimit: uploadSpeedLimit ?? this.uploadSpeedLimit,
      downloadSpeedLimit: downloadSpeedLimit ?? this.downloadSpeedLimit,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      systemTrayEnabled: systemTrayEnabled ?? this.systemTrayEnabled,
      language: language ?? this.language,
      routingRules: routingRules ?? this.routingRules,
      bypassList: bypassList ?? this.bypassList,
    );
  }
}


