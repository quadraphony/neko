import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nekobox_app/services/vpn_service.dart';
// Constants for better maintainability
const double _cardElevation = 4.0;
const double _defaultPadding = 16.0;
const double _iconSize = 24.0;
const double _buttonHeight = 56.0;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..addStatusListener((status) {
        // Ensure animation stops properly when completed
        if (status == AnimationStatus.dismissed && !mounted) {
          _pulseController.dispose();
        }
      });

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnService>(
      builder: (context, vpnService, child) {
        // Manage pulse animation based on connection status
        if (vpnService.isConnecting) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else if (vpnService.isConnected) {
          _pulseController.stop();
        } else {
          _pulseController.reset();
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              if (vpnService.isConnected && vpnService.activeProfile != null) {
                await vpnService.refreshStats(); // Assume VpnService has a refresh method
              }
              return Future.value(); // Ensure Future is returned
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(_defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Connection Status Card
                  _buildConnectionStatusCard(vpnService),
                  const SizedBox(height: _defaultPadding),

                  // Connection Stats Card
                  if (vpnService.isConnected && vpnService.stats != null) ...[
                    _buildConnectionStatsCard(vpnService),
                    const SizedBox(height: _defaultPadding),
                  ],

                  // Active Profile Card
                  if (vpnService.activeProfile != null) ...[
                    _buildActiveProfileCard(vpnService),
                    const SizedBox(height: _defaultPadding),
                  ],

                  // Connection Control
                  _buildConnectionControl(vpnService),
                  const SizedBox(height: _defaultPadding * 1.5),

                  // Quick Actions
                  _buildQuickActions(context, vpnService),
                  const SizedBox(height: _defaultPadding),

                  // Recent Logs
                  _buildRecentLogs(vpnService),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatusCard(VpnService vpnService) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (vpnService.status) {
      case VpnStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Connected';
        break;
      case VpnStatus.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        statusText = 'Connecting...';
        break;
      case VpnStatus.disconnecting:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        statusText = 'Disconnecting...';
        break;
      case VpnStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Error';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'Disconnected';
    }

    return Card(
      elevation: _cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: vpnService.isConnecting ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor, width: 3),
                    ),
                    child: Icon(
                      statusIcon,
                      size: 40,
                      color: statusColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: _defaultPadding),
            Text(
              statusText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (vpnService.activeProfile != null) ...[
              const SizedBox(height: 8),
              Text(
                vpnService.activeProfile!.name,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${vpnService.activeProfile!.server}:${vpnService.activeProfile!.port}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatsCard(VpnService vpnService) {
    final stats = vpnService.stats;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      elevation: _cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(_defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: _defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Upload',
                    _formatBytes(stats.uploadBytes),
                    Icons.upload,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Download',
                    _formatBytes(stats.downloadBytes),
                    Icons.download,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _defaultPadding),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Duration',
                    _formatDuration(stats.connectionTime),
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Ping',
                    '${stats.ping}ms',
                    Icons.speed,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: _iconSize),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveProfileCard(VpnService vpnService) {
    final profile = vpnService.activeProfile!;
    final protocol = profile.protocol.toString().split(".").last;

    return Card(
      elevation: _cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(_defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getProtocolColor(protocol),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      _getProtocolAbbreviation(protocol),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${protocol.toUpperCase()} • ${profile.server}:${profile.port}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionControl(VpnService vpnService) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: _buttonHeight,
          child: ElevatedButton.icon(
            onPressed: vpnService.isConnecting || vpnService.status == VpnStatus.disconnecting
                ? null
                : () async {
                    try {
                      if (vpnService.isConnected) {
                        await vpnService.disconnect();
                      } else {
                        if (vpnService.profiles.isEmpty) {
                          _showNoProfilesDialog();
                        } else {
                          _showProfileSelectionDialog(vpnService);
                        }
                      }
                    } catch (e) {
                      _showErrorDialog('Connection Error', e.toString());
                    }
                  },
            icon: Icon(
              vpnService.isConnected ? Icons.stop : Icons.play_arrow,
              size: _iconSize,
            ),
            label: Text(
              vpnService.isConnected ? 'Disconnect' : 'Connect',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: vpnService.isConnected ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (vpnService.isConnecting || vpnService.status == VpnStatus.disconnecting) ...[
          const SizedBox(height: _defaultPadding),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, VpnService vpnService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Add Profile',
                Icons.add,
                Colors.blue,
                () => _navigateToTab(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                'Import Config',
                Icons.download,
                Colors.green,
                () => _showImportDialog(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionCard(
                'View Logs',
                Icons.list_alt,
                Colors.orange,
                () => _navigateToTab(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: _cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(_defaultPadding),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLogs(VpnService vpnService) {
    final recentLogs = vpnService.logs.take(3).toList();

    if (recentLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: _cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(_defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => _navigateToTab(2),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentLogs.map((log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getLogLevelColor(log.level),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.message,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(log.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _getProtocolColor(String protocol) {
    switch (protocol) {
      case 'vmess':
        return Colors.blue;
      case 'vless':
        return Colors.green;
      case 'trojan':
        return Colors.red;
      case 'shadowsocks':
        return Colors.purple;
      case 'wireguard':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getProtocolAbbreviation(String protocol) {
    switch (protocol) {
      case 'vmess':
        return 'VM';
      case 'vless':
        return 'VL';
      case 'trojan':
        return 'TJ';
      case 'shadowsocks':
        return 'SS';
      case 'wireguard':
        return 'WG';
      case 'socks':
        return 'SK';
      case 'http':
        return 'HT';
      default:
        return 'UN';
    }
  }

  Color _getLogLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARN':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _navigateToTab(int index) {
    // Assuming the app uses a BottomNavigationBar or similar
    // Access the parent BottomNavigationBar widget or TabController
    final bottomNavKey = context.findAncestorStateOfType<NavigatorState>()?.widget.key;
    if (bottomNavKey != null) {
      DefaultTabController.of(context)?.animateTo(index);
    } else {
      // Fallback to a navigation route
      Navigator.of(context).pushNamed('/tabs/$index');
    }
  }

  void _showProfileSelectionDialog(VpnService vpnService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Profile'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vpnService.profiles.length,
            itemBuilder: (context, index) {
              final profile = vpnService.profiles[index];
              final protocol = profile.protocol.toString().split(".").last;
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getProtocolColor(protocol),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      _getProtocolAbbreviation(protocol),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  profile.name,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${profile.server}:${profile.port}',
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  try {
                    await vpnService.connect(profile);
                  } catch (e) {
                    _showErrorDialog('Connection Error', e.toString());
                  }
                },
              );
            },
          ),
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

  void _showNoProfilesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Profiles'),
        content: const Text('You need to add at least one VPN profile before connecting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToTab(1);
            },
            child: const Text('Add Profile'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    // Navigate to profiles tab for import functionality
    _navigateToTab(1);
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
