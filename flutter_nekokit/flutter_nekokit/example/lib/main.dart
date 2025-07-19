import 'package:flutter/material.dart';
import 'package:flutter_nekokit/flutter_nekokit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterNekokitPlugin = FlutterNekokit();
  String _status = 'Unknown';
  String _stats = 'No stats available';
  String _version = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String version;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      await _flutterNekokitPlugin.initNekoBox();
      version = await _flutterNekokitPlugin.getVersion();
    } catch (e) {
      version = 'Failed to get version: $e';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _version = version;
    });
  }

  Future<void> _startProxy() async {
    try {
      // Example sing-box configuration (simplified)
      const config = '''
      {
        "log": {
          "level": "info"
        },
        "inbounds": [
          {
            "type": "mixed",
            "listen": "127.0.0.1",
            "listen_port": 2080
          }
        ],
        "outbounds": [
          {
            "type": "direct"
          }
        ]
      }
      ''';
      
      await _flutterNekokitPlugin.startProxy(config);
      _updateStatus();
    } catch (e) {
      setState(() {
        _status = 'Failed to start proxy: $e';
      });
    }
  }

  Future<void> _stopProxy() async {
    try {
      await _flutterNekokitPlugin.stopProxy();
      _updateStatus();
    } catch (e) {
      setState(() {
        _status = 'Failed to stop proxy: $e';
      });
    }
  }

  Future<void> _updateStatus() async {
    try {
      final status = await _flutterNekokitPlugin.getProxyStatus();
      final stats = await _flutterNekokitPlugin.getConnectionStats();
      setState(() {
        _status = status;
        _stats = stats;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to get status: $e';
        _stats = 'Failed to get stats: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter NekoKit Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Version: $_version',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: $_status',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stats: $_stats',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startProxy,
                child: const Text('Start Proxy'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _stopProxy,
                child: const Text('Stop Proxy'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _updateStatus,
                child: const Text('Update Status'),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This example demonstrates the Flutter NekoKit plugin API. '
                        'To fully function, you need to integrate the NekoBoxForAndroid '
                        'sing-box core into the Android and iOS native modules.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

