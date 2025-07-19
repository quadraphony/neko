import 'package:flutter/services.dart';

class KillSwitchService {
  static const MethodChannel _channel = MethodChannel('com.nekobox.app/kill_switch');

  Future<void> enableKillSwitch() async {
    try {
      await _channel.invokeMethod('enableKillSwitch');
    } on PlatformException catch (e) {
      print("Failed to enable kill switch: ${e.message}");
    }
  }

  Future<void> disableKillSwitch() async {
    try {
      await _channel.invokeMethod('disableKillSwitch');
    } on PlatformException catch (e) {
      print("Failed to disable kill switch: ${e.message}");
    }
  }

  Future<bool> isKillSwitchEnabled() async {
    try {
      return await _channel.invokeMethod('isKillSwitchEnabled');
    } on PlatformException catch (e) {
      print("Failed to check kill switch status: ${e.message}");
      return false;
    }
  }
}

