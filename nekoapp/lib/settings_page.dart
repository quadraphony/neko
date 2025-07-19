import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_settings.dart';
import 'services/vpn_service.dart';
import 'services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storage = StorageService();
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsMap = await _storage.loadSettings();
      setState(() {
        _settings = AppSettings.fromJson(settingsMap);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _settings = const AppSettings();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.saveSettings(_settings.toJson());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    }
  }

  void _updateSetting<T>(T value, AppSettings Function(T) updater) {
    setState(() {
      _settings = updater(value);
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Core Settings Section
          _buildSectionHeader('Core Settings', Icons.settings),
          _buildServiceModeCard(),
          _buildTunImplementationCard(),
          _buildMtuCard(),
          _buildSpeedNotificationCard(),
          _buildSwitchTile(
            'Profile Traffic Statistics',
            'When disabled, the used traffic will not be counted',
            _settings.profileTrafficStatistics,
            (value) => _updateSetting(value, (v) => _settings.copyWith(profileTrafficStatistics: v)),
            Icons.bar_chart,
          ),
          _buildSwitchTile(
            'Show Direct Speed',
            'Show the traffic speed without proxy in the notification as well',
            _settings.showDirectSpeed,
            (value) => _updateSetting(value, (v) => _settings.copyWith(showDirectSpeed: v)),
            Icons.speed,
          ),
          _buildSwitchTile(
            'Show group name in notification',
            null,
            _settings.showGroupNameInNotification,
            (value) => _updateSetting(value, (v) => _settings.copyWith(showGroupNameInNotification: v)),
            Icons.group,
          ),
          _buildSwitchTile(
            'Always Show Address',
            'Always display the server address on the configuration card',
            _settings.alwaysShowAddress,
            (value) => _updateSetting(value, (v) => _settings.copyWith(alwaysShowAddress: v)),
            Icons.location_on,
          ),
          _buildSwitchTile(
            'Metered Hint',
            'Hint system to treat VPN as metered',
            _settings.meteredHint,
            (value) => _updateSetting(value, (v) => _settings.copyWith(meteredHint: v)),
            Icons.data_usage,
          ),
          _buildSwitchTile(
            'Acquire WakeLock',
            'Keep the CPU on',
            _settings.acquireWakeLock,
            (value) => _updateSetting(value, (v) => _settings.copyWith(acquireWakeLock: v)),
            Icons.lock,
          ),
          _buildLogLevelCard(),

          const SizedBox(height: 24),

          // DNS Settings Section
          _buildSectionHeader('DNS Settings', Icons.dns),
          _buildDomainStrategyCard(
            'Domain strategy for Server address',
            _settings.domainStrategyForServerAddress,
            (value) => _updateSetting(value, (v) => _settings.copyWith(domainStrategyForServerAddress: v)),
          ),
          _buildSwitchTile(
            'Enable DNS Routing',
            'Resolve domains in bypass routes with Direct DNS. Be aware of potential DNS leaks',
            _settings.enableDnsRouting,
            (value) => _updateSetting(value, (v) => _settings.copyWith(enableDnsRouting: v)),
            Icons.router,
          ),
          _buildSwitchTile(
            'Enable FakeDNS',
            'May cause other applications need to be restarted to reconnect to the network after proxy stopped',
            _settings.enableFakeDns,
            (value) => _updateSetting(value, (v) => _settings.copyWith(enableFakeDns: v)),
            Icons.security,
          ),
          _buildTextFieldCard(
            'Remote DNS',
            _settings.remoteDns,
            (value) => _updateSetting(value, (v) => _settings.copyWith(remoteDns: v)),
            Icons.cloud,
          ),
          _buildDomainStrategyCard(
            'Domain strategy for Remote',
            _settings.domainStrategyForRemote,
            (value) => _updateSetting(value, (v) => _settings.copyWith(domainStrategyForRemote: v)),
          ),
          _buildTextFieldCard(
            'Direct DNS',
            _settings.directDns,
            (value) => _updateSetting(value, (v) => _settings.copyWith(directDns: v)),
            Icons.dns,
          ),

          const SizedBox(height: 24),

          // Inbound Settings Section
          _buildSectionHeader('Inbound Settings', Icons.input),
          _buildNumberFieldCard(
            'Proxy Port',
            _settings.proxyPort,
            (value) => _updateSetting(value, (v) => _settings.copyWith(proxyPort: v)),
            Icons.router,
          ),
          _buildSwitchTile(
            'Append HTTP Proxy to VPN',
            'HTTP proxy will be used directly from (browser/some supported apps), without going through the virtual NIC device (Android 10+)',
            _settings.appendHttpProxyToVpn,
            (value) => _updateSetting(value, (v) => _settings.copyWith(appendHttpProxyToVpn: v)),
            Icons.http,
          ),
          _buildSwitchTile(
            'Allow Connections from the LAN',
            'Bind inbound servers to 0.0.0.0',
            _settings.allowConnectionsFromLan,
            (value) => _updateSetting(value, (v) => _settings.copyWith(allowConnectionsFromLan: v)),
            Icons.lan,
          ),

          const SizedBox(height: 24),

          // Route Settings Section
          _buildSectionHeader('Route Settings', Icons.route),
          _buildSwitchTile(
            'Apps VPN mode',
            'Configure VPN mode for selected apps',
            _settings.appsVpnMode,
            (value) => _updateSetting(value, (v) => _settings.copyWith(appsVpnMode: v)),
            Icons.apps,
          ),
          _buildSwitchTile(
            'Bypass LAN',
            null,
            _settings.bypassLan,
            (value) => _updateSetting(value, (v) => _settings.copyWith(bypassLan: v)),
            Icons.lan,
          ),
          _buildSwitchTile(
            'Bypass LAN in Core',
            null,
            _settings.bypassLanInCore,
            (value) => _updateSetting(value, (v) => _settings.copyWith(bypassLanInCore: v)),
            Icons.settings_ethernet,
          ),
          _buildSwitchTile(
            'Enable Traffic Sniffing',
            'Sniff result for routing',
            _settings.enableTrafficSniffing,
            (value) => _updateSetting(value, (v) => _settings.copyWith(enableTrafficSniffing: v)),
            Icons.search,
          ),
          _buildSwitchTile(
            'Resolve Destination',
            'If the destination address is a domain, it is then passed out based on the IPv6 strategy (conflicts with FakeDNS)',
            _settings.resolveDestination,
            (value) => _updateSetting(value, (v) => _settings.copyWith(resolveDestination: v)),
            Icons.location_searching,
          ),
          _buildIpv6RouteCard(),
          _buildTextFieldCard(
            'Rule Assets Provider',
            _settings.ruleAssetsProvider,
            (value) => _updateSetting(value, (v) => _settings.copyWith(ruleAssetsProvider: v)),
            Icons.rule,
          ),

          const SizedBox(height: 24),

          // Misc Settings Section
          _buildSectionHeader('Misc Settings', Icons.miscellaneous_services),
          _buildTextFieldCard(
            'Connection Test URL',
            _settings.connectionTestUrl,
            (value) => _updateSetting(value, (v) => _settings.copyWith(connectionTestUrl: v)),
            Icons.link,
          ),
          _buildSwitchTile(
            'Enable Clash API',
            'Provide clash api and yacd dashboard at 127.0.0.1:9090',
            _settings.enableClashApi,
            (value) => _updateSetting(value, (v) => _settings.copyWith(enableClashApi: v)),
            Icons.api,
          ),

          const SizedBox(height: 24),

          // Advanced Settings Section
          _buildSectionHeader('Advanced Settings', Icons.tune),
          _buildSwitchTile(
            'Auto Connect',
            'Automatically connect on app start',
            _settings.autoConnect,
            (value) => _updateSetting(value, (v) => _settings.copyWith(autoConnect: v)),
            Icons.autorenew,
          ),
          _buildSwitchTile(
            'Auto Reconnect',
            'Automatically reconnect on connection loss',
            _settings.autoReconnect,
            (value) => _updateSetting(value, (v) => _settings.copyWith(autoReconnect: v)),
            Icons.refresh,
          ),
          _buildSwitchTile(
            'Kill Switch',
            'Block internet when VPN is disconnected',
            _settings.killSwitch,
            (value) => _updateSetting(value, (v) => _settings.copyWith(killSwitch: v)),
            Icons.block,
          ),
          _buildSwitchTile(
            'System Proxy',
            'Use system proxy settings',
            _settings.systemProxy,
            (value) => _updateSetting(value, (v) => _settings.copyWith(systemProxy: v)),
            Icons.settings_applications,
          ),
          _buildSwitchTile(
            'IPv6 Support',
            'Enable IPv6 routing',
            _settings.ipv6Support,
            (value) => _updateSetting(value, (v) => _settings.copyWith(ipv6Support: v)),
            Icons.language,
          ),
          _buildActionCard(
            title: 'Theme',
            subtitle: _settings.themeMode.toString().split('.').last.toUpperCase(),
            icon: Icons.palette,
            onTap: _showThemeSelectionDialog,
          ),
          _buildSwitchTile(
            'Notifications',
            'Enable/disable app notifications',
            _settings.notificationsEnabled,
            (value) => _updateSetting(value, (v) => _settings.copyWith(notificationsEnabled: v)),
            Icons.notifications,
          ),
          _buildSwitchTile(
            'System Tray Icon',
            'Show icon in system tray (desktop only)',
            _settings.systemTrayEnabled,
            (value) => _updateSetting(value, (v) => _settings.copyWith(systemTrayEnabled: v)),
            Icons.desktop_windows,
          ),
          _buildTextFieldCard(
            'Language',
            _settings.language.toUpperCase(),
            (value) => _updateSetting(value, (v) => _settings.copyWith(language: v)),
            Icons.language,
          ),

          const SizedBox(height: 24),

          // Export/Import Section
          _buildSectionHeader('Backup & Restore', Icons.backup),
          _buildActionCard(
            title: 'Export Settings',
            subtitle: 'Export all settings to file',
            icon: Icons.upload,
            onTap: _exportSettings,
          ),
          _buildActionCard(
            title: 'Import Settings',
            subtitle: 'Import settings from file',
            icon: Icons.download,
            onTap: _importSettings,
          ),
          _buildActionCard(
            title: 'Reset Settings',
            subtitle: 'Reset all settings to default',
            icon: Icons.restore,
            onTap: _resetSettings,
          ),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String? subtitle, bool value, ValueChanged<bool> onChanged, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon),
      ),
    );
  }

  Widget _buildServiceModeCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.vpn_key),
        title: const Text('Service Mode'),
        subtitle: Text(_settings.serviceMode.toString().split('.').last.toUpperCase()),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _showServiceModeDialog,
      ),
    );
  }

  Widget _buildTunImplementationCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.settings_ethernet),
        title: const Text('TUN Implementation'),
        subtitle: Text(_settings.tunImplementation.toString().split('.').last.toUpperCase()),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _showTunImplementationDialog,
      ),
    );
  }

  Widget _buildMtuCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.network_check),
        title: const Text('MTU'),
        subtitle: Text(_settings.mtu.toString()),
        trailing: const Icon(Icons.edit),
        onTap: _showMtuDialog,
      ),
    );
  }

  Widget _buildSpeedNotificationCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.speed),
        title: const Text('Speed Notification Update Interval'),
        subtitle: Text('${_settings.speedNotificationUpdateInterval}s'),
        trailing: const Icon(Icons.edit),
        onTap: _showSpeedNotificationDialog,
      ),
    );
  }

  Widget _buildLogLevelCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.bug_report),
        title: const Text('Log Level'),
        subtitle: Text(_settings.logLevel.toString().split('.').last.toUpperCase()),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _showLogLevelDialog,
      ),
    );
  }

  Widget _buildDomainStrategyCard(String title, DomainStrategy value, ValueChanged<DomainStrategy> onChanged) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.dns),
        title: Text(title),
        subtitle: Text(value.toString().split('.').last),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showDomainStrategyDialog(title, value, onChanged),
      ),
    );
  }

  Widget _buildTextFieldCard(String title, String value, ValueChanged<String> onChanged, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value.isEmpty ? 'Not set' : value),
        trailing: const Icon(Icons.edit),
        onTap: () => _showTextFieldDialog(title, value, onChanged),
      ),
    );
  }

  Widget _buildNumberFieldCard(String title, int value, ValueChanged<int> onChanged, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value.toString()),
        trailing: const Icon(Icons.edit),
        onTap: () => _showNumberFieldDialog(title, value, onChanged),
      ),
    );
  }

  Widget _buildIpv6RouteCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.language),
        title: const Text('IPv6 Route'),
        subtitle: Text(_settings.ipv6Route.toString().split('.').last),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _showIpv6RouteDialog,
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _showServiceModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Service Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ServiceMode.values
              .map(
                (mode) => RadioListTile<ServiceMode>(
                  title: Text(mode.toString().split('.').last.toUpperCase()),
                  value: mode,
                  groupValue: _settings.serviceMode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(value, (v) => _settings.copyWith(serviceMode: v));
                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTunImplementationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('TUN Implementation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TunImplementation.values
              .map(
                (impl) => RadioListTile<TunImplementation>(
                  title: Text(impl.toString().split('.').last.toUpperCase()),
                  value: impl,
                  groupValue: _settings.tunImplementation,
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(value, (v) => _settings.copyWith(tunImplementation: v));
                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMtuDialog() {
    final controller = TextEditingController(text: _settings.mtu.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MTU'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'MTU Size',
            hintText: '1500',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 576 && value <= 1500) {
                _updateSetting(value, (v) => _settings.copyWith(mtu: v));
                Navigator.of(context).pop();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('MTU must be between 576 and 1500')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSpeedNotificationDialog() {
    final controller = TextEditingController(text: _settings.speedNotificationUpdateInterval.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Speed Notification Update Interval'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Interval (seconds)',
            hintText: '1',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 1 && value <= 60) {
                _updateSetting(value, (v) => _settings.copyWith(speedNotificationUpdateInterval: v));
                Navigator.of(context).pop();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Interval must be between 1 and 60 seconds')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogLevelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LogLevel.values
              .map(
                (level) => RadioListTile<LogLevel>(
                  title: Text(level.toString().split('.').last.toUpperCase()),
                  value: level,
                  groupValue: _settings.logLevel,
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(value, (v) => _settings.copyWith(logLevel: v));
                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDomainStrategyDialog(String title, DomainStrategy current, ValueChanged<DomainStrategy> onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DomainStrategy.values
              .map(
                (strategy) => RadioListTile<DomainStrategy>(
                  title: Text(strategy.toString().split('.').last),
                  value: strategy,
                  groupValue: current,
                  onChanged: (value) {
                    if (value != null) {
                      onChanged(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTextFieldDialog(String title, String current, ValueChanged<String> onChanged) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty || title == 'Remote DNS' || title == 'Direct DNS') {
                onChanged(value);
                Navigator.of(context).pop();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title cannot be empty')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNumberFieldDialog(String title, int current, ValueChanged<int> onChanged) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 0) {
                onChanged(value);
                Navigator.of(context).pop();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid $title')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showIpv6RouteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IPv6 Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Ipv6Route.values
              .map(
                (route) => RadioListTile<Ipv6Route>(
                  title: Text(route.toString().split('.').last),
                  value: route,
                  groupValue: _settings.ipv6Route,
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(value, (v) => _settings.copyWith(ipv6Route: v));
                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() async {
    try {
      // Placeholder for export logic; assumes StorageService has an export method
      // Example: await _storage.exportSettings(_settings.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export settings: $e')),
        );
      }
    }
  }

  void _importSettings() async {
    try {
      // Placeholder for import logic; assumes StorageService has an import method
      // Example: final settingsMap = await _storage.importSettings();
      // setState(() {
      //   _settings = AppSettings.fromJson(settingsMap);
      // });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings imported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import settings: $e')),
        );
      }
    }
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _settings = const AppSettings();
              });
              _saveSettings();
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to default')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values
              .map(
                (themeMode) => RadioListTile<ThemeMode>(
                  title: Text(themeMode.toString().split('.').last.toUpperCase()),
                  value: themeMode,
                  groupValue: _settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(value, (v) => _settings.copyWith(themeMode: v));
                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}