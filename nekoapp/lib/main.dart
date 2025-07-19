import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'pages/profiles_page.dart';
import 'pages/logs_page.dart';
import 'settings_page.dart';
import 'services/vpn_service.dart';
import 'services/storage_service.dart';
import 'models/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final settingsMap = await StorageService().loadSettings();
    final settings = AppSettings.fromJson(settingsMap);
    setState(() {
      _themeMode = settings.themeMode;
    });
  }

  void setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
    // Save theme preference
    final settingsMap = await StorageService().loadSettings();
    final currentSettings = AppSettings.fromJson(settingsMap);
    StorageService().saveSettings(currentSettings.copyWith(themeMode: themeMode).toJson());
  }

  ThemeMode _getThemeModeFromString(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VpnService()..initialize(),
      child: MaterialApp(
        title: 'NekoBox VPN',
        themeMode: _themeMode,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    ProfilesPage(),
    LogsPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnService>(
      builder: (context, vpnService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('NekoBox VPN'),
            actions: [
              // VPN Status Indicator
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vpnService.isConnected 
                        ? Icons.vpn_lock 
                        : Icons.vpn_lock_outlined,
                      color: vpnService.isConnected 
                        ? Colors.green 
                        : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      vpnService.isConnected 
                        ? 'Connected' 
                        : 'Disconnected',
                      style: TextStyle(
                        color: vpnService.isConnected 
                          ? Colors.green 
                          : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profiles',
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Logs',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
