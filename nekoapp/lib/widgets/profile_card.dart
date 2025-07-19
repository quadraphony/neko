import 'package:flutter/material.dart';
import '../models/vpn_profile.dart';

class ProfileCard extends StatelessWidget {
  final VpnProfile profile;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTest;

  const ProfileCard({
    super.key,
    required this.profile,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Selection Checkbox
                  if (isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap,
                    ),
                  
                  // Protocol Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getProtocolColor(profile.protocol).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getProtocolIcon(profile.protocol),
                      color: _getProtocolColor(profile.protocol),
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Profile Name and Group
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isFavorite)
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                          ],
                        ),
                        if (profile.group != null)
                          Text(
                            profile.group!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Actions Menu
                  if (!isSelectionMode)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'duplicate':
                            onDuplicate();
                            break;
                          case 'test':
                            onTest();
                            break;
                          case 'favorite':
                            onToggleFavorite();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: ListTile(
                            leading: Icon(Icons.copy),
                            title: Text('Duplicate'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'test',
                          child: ListTile(
                            leading: Icon(Icons.speed),
                            title: Text('Test'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'favorite',
                          child: ListTile(
                            leading: Icon(profile.isFavorite ? Icons.star : Icons.star_border),
                            title: Text(profile.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Server Information
              Row(
                children: [
                  Icon(
                    Icons.dns,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profile.server,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    ':${profile.port}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Protocol and Last Used
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProtocolColor(profile.protocol).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getProtocolColor(profile.protocol).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      profile.protocol.toString().split('.').last.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getProtocolColor(profile.protocol),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (profile.updatedAt != null)
                    Text(
                      'Last used: ${_formatLastUsed(profile.updatedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              
              // Connection Status (if connected)
              if (profile.isActive) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Connected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getProtocolColor(VpnProtocol protocol) {
    switch (protocol) {
      case VpnProtocol.vmess:
        return Colors.blue;
      case VpnProtocol.vless:
        return Colors.green;
      case VpnProtocol.trojan:
        return Colors.red;
      case VpnProtocol.shadowsocks:
        return Colors.purple;
      case VpnProtocol.wireguard:
        return Colors.orange;
      case VpnProtocol.hysteria:
        return Colors.pink;
      case VpnProtocol.tuic:
        return Colors.teal;
      case VpnProtocol.socks:
        return Colors.brown;
      case VpnProtocol.http:
        return Colors.indigo;
      case VpnProtocol.ssh:
        return Colors.cyan;
      case VpnProtocol.hysteria2:
        return Colors.deepPurple;
      case VpnProtocol.naiveProxy:
        return Colors.lime;
      case VpnProtocol.mieru:
        return Colors.deepOrange;
      case VpnProtocol.trojanGo:
        return Colors.deepOrangeAccent;
      case VpnProtocol.anyTls:
        return Colors.grey;
      case VpnProtocol.shadowTls:
        return Colors.blueGrey;
      case VpnProtocol.naive:
        return Colors.lightGreen;
      case VpnProtocol.brook:
        return Colors.lightBlueAccent;
      case VpnProtocol.snell:
        return Colors.amberAccent;
    }
  }

  IconData _getProtocolIcon(VpnProtocol protocol) {
    switch (protocol) {
      case VpnProtocol.vmess:
      case VpnProtocol.vless:
        return Icons.flight_takeoff;
      case VpnProtocol.trojan:
        return Icons.security;
      case VpnProtocol.shadowsocks:
        return Icons.visibility_off;
      case VpnProtocol.wireguard:
        return Icons.vpn_lock;
      case VpnProtocol.hysteria:
      case VpnProtocol.hysteria2:
        return Icons.speed;
      case VpnProtocol.tuic:
        return Icons.tune;
      case VpnProtocol.socks:
        return Icons.swap_horiz;
      case VpnProtocol.http:
        return Icons.http;
      case VpnProtocol.ssh:
        return Icons.terminal;
      case VpnProtocol.naiveProxy:
        return Icons.lightbulb_outline;
      case VpnProtocol.mieru:
        return Icons.visibility;
      case VpnProtocol.trojanGo:
        return Icons.rocket_launch;
      case VpnProtocol.anyTls:
        return Icons.link;
      case VpnProtocol.shadowTls:
        return Icons.vpn_key;
      case VpnProtocol.naive:
        return Icons.lightbulb_outline;
      case VpnProtocol.brook:
        return Icons.water;
      case VpnProtocol.snell:
        return Icons.flash_on;
    }
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }




}

