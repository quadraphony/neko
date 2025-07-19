import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_nekokit_method_channel.dart';

abstract class FlutterNekokitPlatform extends PlatformInterface {
  /// Constructs a FlutterNekokitPlatform.
  FlutterNekokitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNekokitPlatform _instance = MethodChannelFlutterNekokit();

  /// The default instance of [FlutterNekokitPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterNekokit].
  static FlutterNekokitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterNekokitPlatform] when
  /// they register themselves.
  static set instance(FlutterNekokitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initNekoBox() {
    throw UnimplementedError('initNekoBox() has not been implemented.');
  }

  Future<void> startProxy(String config) {
    throw UnimplementedError('startProxy() has not been implemented.');
  }

  Future<void> stopProxy() {
    throw UnimplementedError('stopProxy() has not been implemented.');
  }

  Future<String> getProxyStatus() {
    throw UnimplementedError('getProxyStatus() has not been implemented.');
  }

  Future<String> getConnectionStats() {
    throw UnimplementedError('getConnectionStats() has not been implemented.');
  }

  Future<String> getVersion() {
    throw UnimplementedError('getVersion() has not been implemented.');
  }

  Future<void> updateConfig(String config) {
    throw UnimplementedError('updateConfig() has not been implemented.');
  }
}


