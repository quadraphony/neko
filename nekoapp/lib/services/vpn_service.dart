import 'package:nekobox_app/models/vpn_group.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'subscription_service.dart';

import 'package:flutter_nekokit/flutter_nekokit.dart';
import '../models/vpn_profile.dart' show VpnProfile;
import 'package:flutter/material.dart';
import 'package:nekobox_app/models/vpn_log_entry.dart';


class VpnService extends ChangeNotifier {
  ValueNotifier<List<VpnLogEntry>> _logs = ValueNotifier([]);
  List<VpnGroup> _groups = [];

  List<VpnGroup> get groups => List.unmodifiable(_groups);

  Future<void> addGroup(VpnGroup group) async {
    _groups.add(group);
    notifyListeners();
  }


  void notifyListeners() {
    // Placeholder for notifyListeners, replace with actual implementation if needed
    super.notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}



import 'package:nekobox_app/models/vpn_status.dart';
import 'package:nekobox_app/models/vpn_profile.dart';




  VpnStatus _status = VpnStatus.disconnected;
  VpnProfile? _activeProfile;
  bool _isConnecting = false;
  Map<String, dynamic>? _stats;

  VpnStatus get status => _status;
  bool get isConnected => _status == VpnStatus.connected;
  bool get isConnecting => _isConnecting;
  VpnProfile? get activeProfile => _activeProfile;
  Map<String, dynamic>? get stats => _stats;
  ValueNotifier<List<VpnLogEntry>> get logs => _logs;

  List<VpnProfile> get profiles => _groups.expand((group) => group.profiles).toList();

  Future<void> initialize() async {
    // TODO: Implement initialization logic
    debugPrint("VPN Service initialized");
    _status = VpnStatus.disconnected;
    notifyListeners();
  }

  Future<void> connect(VpnProfile profile) async {
    _isConnecting = true;
    _status = VpnStatus.connecting;
    _activeProfile = profile;
    notifyListeners();

    try {
      // TODO: Implement actual connection logic using _nekokit
      await _nekokit.startProxy(profile.toSingBoxConfig());
      _status = VpnStatus.connected;
      debugPrint("Connected to ${profile.name}");
    } catch (e) {
      _status = VpnStatus.error;
      debugPrint("Failed to connect: $e");
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _isConnecting = true;
    _status = VpnStatus.disconnecting;
    notifyListeners();

    try {
      // TODO: Implement actual disconnection logic using _nekokit
      await _nekokit.stopProxy();
      _status = VpnStatus.disconnected;
      _activeProfile = null;
      debugPrint("Disconnected");
    } catch (e) {
      _status = VpnStatus.error;
      debugPrint("Failed to disconnect: $e");
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> refreshStats() async {
    try {
      // TODO: Implement actual stats refresh logic using _nekokit
      final statsJson = await _nekokit.getConnectionStats();
      _stats = jsonDecode(statsJson);
      debugPrint("Stats refreshed: $_stats");
    } catch (e) {
      debugPrint("Failed to refresh stats: $e");
    } finally {
      notifyListeners();
    }
  }

  List<VpnLogEntry> getFilteredLogs() {
    // TODO: Implement actual log filtering logic
    return _logs.value;
  }

  void clearLogs() {
    _logs.value = [];
    notifyListeners();
  }

  void debugPrint(String message) {
    // For now, just print to console. In a real app, you might use a logging library.
    print(message);
  }


