import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/vpn_profile.dart' show VpnProfile;
import '../models/vpn_group.dart';


class StorageService {
  static const String _profilesFile = 'vpn_profiles.json';
  static const String _groupsFile = 'vpn_groups.json';
  static const String _settingsFile = 'vpn_settings.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  Future<void> saveProfile(VpnProfile profile) async {
    final profiles = await loadProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await saveProfiles(profiles);
  }

  Future<void> deleteProfile(String id) async {
    final profiles = await loadProfiles();
    profiles.removeWhere((p) => p.id == id);
    await saveProfiles(profiles);
  }

  // Profile operations
  Future<List<VpnProfile>> loadProfiles() async {
    try {
      final file = await _getFile(_profilesFile);
      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      
      return jsonList.map((json) => VpnProfile.fromJson(json)).toList();
    } catch (e) {
      print('Error loading profiles: $e');
      return [];
    }
  }

  Future<void> saveProfiles(List<VpnProfile> profiles) async {
    try {
      final file = await _getFile(_profilesFile);
      final jsonList = profiles.map((profile) => profile.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving profiles: $e');
    }
  }

  // Group operations
  Future<List<VpnGroup>> loadGroups() async {
    try {
      final file = await _getFile(_groupsFile);
      if (!await file.exists()) {
        return [];
      }

      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      
      return jsonList.map((json) => VpnGroup.fromJson(json)).toList();
    } catch (e) {
      print('Error loading groups: $e');
      return [];
    }
  }

  Future<void> saveGroups(List<VpnGroup> groups) async {
    try {
      final file = await _getFile(_groupsFile);
      final jsonList = groups.map((group) => group.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving groups: $e');
    }
  }

  // Settings operations
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final file = await _getFile(_settingsFile);
      if (!await file.exists()) {
        return _getDefaultSettings();
      }

      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      print('Error loading settings: $e');
      return _getDefaultSettings();
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final file = await _getFile(_settingsFile);
      await file.writeAsString(jsonEncode(settings));
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'autoConnect': false,
      'autoReconnect': true,
      'killSwitch': false,
      'systemProxy': true,
      'ipv6Support': false,
      'connectionTimeout': 30,
      'reconnectDelay': 5,
      'dnsServers': ['8.8.8.8', '8.8.4.4'],
      'dohEnabled': false,
      'adBlockEnabled': false,
      'malwareProtectionEnabled': false,
      'leakProtectionEnabled': true,
      'webrtcLeakProtectionEnabled': true,
      'userAgentRandomizationEnabled': false,
      'encryptionLevel': 'high',
      'connectionPoolingEnabled': true,
      'multiplexingEnabled': true,
      'dataCompressionEnabled': false,
      'maxConnections': 100,
      'congestionControl': 'bbr',
      'speedTestEnabled': true,
      'trafficMonitoringEnabled': true,
      'bandwidthLimitEnabled': false,
      'uploadSpeedLimit': 0,
      'downloadSpeedLimit': 0,
      'theme': 'system',
      'notificationsEnabled': true,
      'systemTrayEnabled': true,
      'language': 'en',
      'routingRules': [],
      'bypassList': [],
      'logLevel': 'info',
    };
  }

  // Import/Export operations
  Future<String> exportProfiles(List<VpnProfile> profiles) async {
    try {
      final jsonList = profiles.map((profile) => profile.toJson()).toList();
      return jsonEncode({
        'version': '1.0',
        'type': 'nekobox_profiles',
        'profiles': jsonList,
        'exportedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to export profiles: $e');
    }
  }

  Future<List<VpnProfile>> importProfiles(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      
      if (data['type'] != 'nekobox_profiles') {
        throw Exception('Invalid profile format');
      }
      
      final List<dynamic> profilesJson = data['profiles'];
      return profilesJson.map((json) => VpnProfile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to import profiles: $e');
    }
  }

  Future<String> exportGroups(List<VpnGroup> groups) async {
    try {
      final jsonList = groups.map((group) => group.toJson()).toList();
      return jsonEncode({
        'version': '1.0',
        'type': 'nekobox_groups',
        'groups': jsonList,
        'exportedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to export groups: $e');
    }
  }

  Future<List<VpnGroup>> importGroups(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      
      if (data['type'] != 'nekobox_groups') {
        throw Exception('Invalid group format');
      }
      
      final List<dynamic> groupsJson = data['groups'];
      return groupsJson.map((json) => VpnGroup.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to import groups: $e');
    }
  }

  // Backup operations
  Future<void> createBackup() async {
    try {
      final profiles = await loadProfiles();
      final groups = await loadGroups();
      final settings = await loadSettings();
      
      final backup = {
        'version': '1.0',
        'type': 'nekobox_backup',
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
        'settings': settings,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      final file = await _getFile('backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonEncode(backup));
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<void> restoreBackup(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      
      if (data['type'] != 'nekobox_backup') {
        throw Exception('Invalid backup format');
      }
      
      // Restore profiles
      final List<dynamic> profilesJson = data['profiles'];
      final profiles = profilesJson.map((json) => VpnProfile.fromJson(json)).toList();
      await saveProfiles(profiles);
      
      // Restore groups
      final List<dynamic> groupsJson = data['groups'];
      final groups = groupsJson.map((json) => VpnGroup.fromJson(json)).toList();
      await saveGroups(groups);
      
      // Restore settings
      final settings = data['settings'] as Map<String, dynamic>;
      await saveSettings(settings);
      
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }
}

