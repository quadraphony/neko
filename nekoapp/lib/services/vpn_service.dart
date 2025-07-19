import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_nekokit/flutter_nekokit.dart';
import '../models/vpn_profile.dart';
import 'storage_service.dart';
import 'subscription_service.dart';

enum VpnStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error
}

class VpnConnectionStats {
  final int uploadBytes;
  final int downloadBytes;
  final Duration connectionTime;
  final String serverLocation;
  final int ping;

  VpnConnectionStats({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.connectionTime,
    required this.serverLocation,
    required this.ping,
  });

  factory VpnConnectionStats.fromJson(Map<String, dynamic> json) {
    return VpnConnectionStats(
      uploadBytes: json['uploadBytes'] ?? 0,
      downloadBytes: json['downloadBytes'] ?? 0,
      connectionTime: Duration(seconds: json['connectionTime'] ?? 0),
      serverLocation: json['serverLocation'] ?? 'Unknown',
      ping: json['ping'] ?? 0,
    );
  }
}

class VpnLogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String? tag;

  VpnLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
  });

  factory VpnLogEntry.fromJson(Map<String, dynamic> json) {
    return VpnLogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: json['level'],
      message: json['message'],
      tag: json['tag'],
    );
  }
}

class VpnService extends ChangeNotifier {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  final FlutterNekokit _nekokit = FlutterNekokit();
  final StorageService _storage = StorageService();
  final SubscriptionService _subscription = SubscriptionService();

  VpnStatus _status = VpnStatus.disconnected;
  VpnProfile? _activeProfile;
  VpnConnectionStats? _stats;
  ValueNotifier<List<VpnLogEntry>> _logs = ValueNotifier([]);
  List<VpnProfile> _profiles = [];
  List<VpnGroup> _groups = [];
  Timer? _statsTimer;
  Timer? _logsTimer;
  DateTime? _connectionStartTime;

  // Getters
  VpnStatus get status => _status;
  VpnProfile? get activeProfile => _activeProfile;
  VpnConnectionStats? get stats => _stats;
  List<VpnLogEntry> get logs => List.unmodifiable(_logs.value);
  List<VpnProfile> get profiles => List.unmodifiable(_profiles);
  List<VpnGroup> get groups => List.unmodifiable(_groups);
  bool get isConnected => _status == VpnStatus.connected;
  bool get isConnecting => _status == VpnStatus.connecting;

  Future<void> initialize() async {
    try {
      await _nekokit.initNekoBox();
      await _loadProfiles();
      await _loadGroups();
      _startLogMonitoring();
      debugPrint('VPN Service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize VPN service: $e');
    }
  }

  Future<void> connect(VpnProfile profile) async {
    if (_status == VpnStatus.connecting || _status == VpnStatus.connected) {
      return;
    }

    try {
      _setStatus(VpnStatus.connecting);
      _activeProfile = profile;
      _connectionStartTime = DateTime.now();

      final config = profile.toSingBoxConfig();
      await _nekokit.startProxy(config);

      _setStatus(VpnStatus.connected);
      _startStatsMonitoring();
      
      _addLog('INFO', 'Connected to ${profile.name} (${profile.server}:${profile.port})');
      
      // Update profile as active
      await _updateProfileActiveStatus(profile.id, true);
      
    } catch (e) {
      _setStatus(VpnStatus.error);
      _addLog('ERROR', 'Failed to connect: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_status == VpnStatus.disconnected || _status == VpnStatus.disconnecting) {
      return;
    }

    try {
      _setStatus(VpnStatus.disconnecting);
      
      await _nekokit.stopProxy();
      
      _setStatus(VpnStatus.disconnected);
      _stopStatsMonitoring();
      
      if (_activeProfile != null) {
        _addLog('INFO', 'Disconnected from ${_activeProfile!.name}');
        await _updateProfileActiveStatus(_activeProfile!.id, false);
      }
      
      _activeProfile = null;
      _stats = null;
      _connectionStartTime = null;
      
    } catch (e) {
      _setStatus(VpnStatus.error);
      _addLog('ERROR', 'Failed to disconnect: $e');
      rethrow;
    }
  }

  Future<void> addProfile(VpnProfile profile) async {
    _profiles.add(profile);
    await _storage.saveProfiles(_profiles);
    notifyListeners();
    _addLog('INFO', 'Added profile: ${profile.name}');
  }

  Future<void> updateProfile(VpnProfile profile) async {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _profiles[index] = profile;
      await _storage.saveProfiles(_profiles);
      notifyListeners();
      _addLog('INFO', 'Updated profile: ${profile.name}');
    }
  }

  Future<void> deleteProfile(String profileId) async {
    final profile = _profiles.firstWhere((p) => p.id == profileId);
    _profiles.removeWhere((p) => p.id == profileId);
    await _storage.saveProfiles(_profiles);
    notifyListeners();
    _addLog('INFO', 'Deleted profile: ${profile.name}');
  }

  Future<void> addGroup(VpnGroup group) async {
    _groups.add(group);
    await _storage.saveGroups(_groups);
    notifyListeners();
    _addLog('INFO', 'Added group: ${group.name}');
  }

  Future<void> importSubscription(String url, String name) async {
    try {
      _addLog('INFO', 'Importing subscription: $name');
      
      final profiles = await _subscription.fetchProfiles(url);
      final group = VpnGroup(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        subscriptionUrl: url,
        profiles: profiles,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSubscription: true,
      );

      await addGroup(group);
      
      // Add profiles to main list
      for (final profile in profiles) {
        await addProfile(profile.copyWith(groupId: group.id));
      }
      
      _addLog('INFO', 'Imported ${profiles.length} profiles from subscription');
      
    } catch (e) {
      _addLog('ERROR', 'Failed to import subscription: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(String groupId) async {
    try {
      final group = _groups.firstWhere((g) => g.id == groupId);
      if (group.subscriptionUrl == null) return;

      _addLog('INFO', 'Updating subscription: ${group.name}');
      
      final newProfiles = await _subscription.fetchProfiles(group.subscriptionUrl!);
      
      // Remove old profiles from this group
      _profiles.removeWhere((p) => p.groupId == groupId);
      
      // Add new profiles
      for (final profile in newProfiles) {
        await addProfile(profile.copyWith(groupId: groupId));
      }
      
      // Update group
      final updatedGroup = VpnGroup(
        id: group.id,
        name: group.name,
        subscriptionUrl: group.subscriptionUrl,
        profiles: newProfiles,
        createdAt: group.createdAt,
        updatedAt: DateTime.now(),
        isSubscription: group.isSubscription,
      );
      
      final index = _groups.indexWhere((g) => g.id == groupId);
      _groups[index] = updatedGroup;
      await _storage.saveGroups(_groups);
      
      _addLog('INFO', 'Updated subscription with ${newProfiles.length} profiles');
      
    } catch (e) {
      _addLog('ERROR', 'Failed to update subscription: $e');
      rethrow;
    }
  }

  Future<void> testProfile(VpnProfile profile) async {
    try {
      _addLog('INFO', 'Testing profile: ${profile.name}');
      
      // Implement ping test or connection test
      final stopwatch = Stopwatch()..start();
      
      // Simple socket connection test
      final socket = await Socket.connect(profile.server, profile.port)
          .timeout(const Duration(seconds: 5));
      
      stopwatch.stop();
      await socket.close();
      
      final ping = stopwatch.elapsedMilliseconds;
      _addLog('INFO', 'Profile test successful: ${profile.name} (${ping}ms)');
      
    } catch (e) {
      _addLog('ERROR', 'Profile test failed: ${profile.name} - $e');
      rethrow;
    }
  }

  void _setStatus(VpnStatus status) {
    _status = status;
    notifyListeners();
  }

  void _startStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final statsJson = await _nekokit.getConnectionStats();
        final statsData = jsonDecode(statsJson);
        
        final connectionTime = _connectionStartTime != null
            ? DateTime.now().difference(_connectionStartTime!)
            : Duration.zero;
            
        _stats = VpnConnectionStats(
          uploadBytes: statsData['uploadBytes'] ?? 0,
          downloadBytes: statsData['downloadBytes'] ?? 0,
          connectionTime: connectionTime,
          serverLocation: _activeProfile?.server ?? 'Unknown',
          ping: statsData['ping'] ?? 0,
        );
        
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to get stats: $e');
      }
    });
  }

  void _stopStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void _startLogMonitoring() {
    _logsTimer?.cancel();
    _logsTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // In a real implementation, this would fetch logs from the native layer
      // For now, we'll just maintain our internal logs
    });
  }

  void _addLog(String level, String message) {
    final log = VpnLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
    );
    
    _logs.value.insert(0, log);
    
    // Keep only last 1000 logs
    if (_logs.value.length > 1000) {
      _logs.value = _logs.value.take(1000).toList();
    }
    
    _logs.notifyListeners();
  }

  Future<void> _loadProfiles() async {
    _profiles = await _storage.loadProfiles();
    notifyListeners();
  }

  Future<void> _loadGroups() async {
    _groups = await _storage.loadGroups();
    notifyListeners();
  }

  Future<void> _updateProfileActiveStatus(String profileId, bool isActive) async {
    // Set all profiles to inactive first
    for (int i = 0; i < _profiles.length; i++) {
      _profiles[i] = _profiles[i].copyWith(isActive: false);
    }
    
    // Set the target profile as active
    if (isActive) {
      final index = _profiles.indexWhere((p) => p.id == profileId);
      if (index != -1) {
        _profiles[index] = _profiles[index].copyWith(isActive: true);
      }
    }
    
    await _storage.saveProfiles(_profiles);
    notifyListeners();
  }

  List<VpnLogEntry> getFilteredLogs({String? level, String? search}) {
    var filteredLogs = _logs.value;
    
    if (level != null && level != 'ALL') {
      filteredLogs = filteredLogs.where((log) => log.level == level).toList();
    }
    
    if (search != null && search.isNotEmpty) {
      filteredLogs = filteredLogs.where((log) => 
        log.message.toLowerCase().contains(search.toLowerCase())
      ).toList();
    }
    
    return filteredLogs;
  }

  void clearLogs() {
    _logs.value.clear();
    _logs.notifyListeners();
    _addLog("INFO", "Logs cleared");
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _logsTimer?.cancel();
    super.dispose();
  }
}

