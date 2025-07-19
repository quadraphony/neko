import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_nekokit_platform_interface.dart';

/// An implementation of [FlutterNekokitPlatform] that uses method channels.
class MethodChannelFlutterNekokit extends FlutterNekokitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_nekokit');

  @override
  Future<void> initNekoBox() async {
    await methodChannel.invokeMethod<void>('initNekoBox');
  }

  @override
  Future<void> startProxy(String config) async {
    await methodChannel.invokeMethod<void>('startProxy', {'config': config});
  }

  @override
  Future<void> stopProxy() async {
    await methodChannel.invokeMethod<void>('stopProxy');
  }

  @override
  Future<String> getProxyStatus() async {
    final status = await methodChannel.invokeMethod<String>('getProxyStatus');
    return status ?? 'Unknown';
  }

  @override
  Future<String> getConnectionStats() async {
    final stats = await methodChannel.invokeMethod<String>('getConnectionStats');
    return stats ?? 'No stats available';
  }

  @override
  Future<String> getVersion() async {
    final version = await methodChannel.invokeMethod<String>('getVersion');
    return version ?? 'Unknown';
  }

  @override
  Future<void> updateConfig(String config) async {
    await methodChannel.invokeMethod<void>('updateConfig', {'config': config});
  }
}

