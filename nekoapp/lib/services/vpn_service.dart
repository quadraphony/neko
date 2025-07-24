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



class VpnService extends ChangeNotifier with DiagnosticableMixin {
  final FlutterNekokit _nekokit = FlutterNekokit();
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


