library flutter_nekokit;

import 'flutter_nekokit_platform_interface.dart';

/// A Flutter plugin for integrating with NekoBoxForAndroid's sing-box core.
class FlutterNekokit {
  /// Initialize the NekoBox core.
  Future<void> initNekoBox() {
    return FlutterNekokitPlatform.instance.initNekoBox();
  }

  /// Start the proxy with the given configuration.
  Future<void> startProxy(String config) {
    return FlutterNekokitPlatform.instance.startProxy(config);
  }

  /// Stop the proxy.
  Future<void> stopProxy() {
    return FlutterNekokitPlatform.instance.stopProxy();
  }

  /// Get the current proxy status.
  Future<String> getProxyStatus() {
    return FlutterNekokitPlatform.instance.getProxyStatus();
  }

  /// Get connection statistics.
  Future<String> getConnectionStats() {
    return FlutterNekokitPlatform.instance.getConnectionStats();
  }

  /// Get the NekoBox core version.
  Future<String> getVersion() {
    return FlutterNekokitPlatform.instance.getVersion();
  }

  /// Update the proxy configuration.
  Future<void> updateConfig(String config) {
    return FlutterNekokitPlatform.instance.updateConfig(config);
  }
}

