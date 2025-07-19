import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nekokit/flutter_nekokit.dart';
import 'package:flutter_nekokit/flutter_nekokit_platform_interface.dart';
import 'package:flutter_nekokit/flutter_nekokit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterNekokitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterNekokitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterNekokitPlatform initialPlatform = FlutterNekokitPlatform.instance;

  test('$MethodChannelFlutterNekokit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterNekokit>());
  });

  test('getPlatformVersion', () async {
    FlutterNekokit flutterNekokitPlugin = FlutterNekokit();
    MockFlutterNekokitPlatform fakePlatform = MockFlutterNekokitPlatform();
    FlutterNekokitPlatform.instance = fakePlatform;

    expect(await flutterNekokitPlugin.getPlatformVersion(), '42');
  });
}
