import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  final List<ProxyProfile> _profiles = [];
  ProxyProfile? _selectedProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proxy Profiles',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FilledButton.icon(
                onPressed: _showAddProfileDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Profile'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Profiles List
          Expanded(
            child: _profiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No profiles yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a proxy profile to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      final isSelected = profile == _selectedProfile;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            child: Icon(
                              _getProtocolIcon(profile.protocol),
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          title: Text(profile.name),
                          subtitle: Text('${profile.protocol} • ${profile.server}:${profile.port}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _showEditProfileDialog(profile);
                                      break;
                                    case 'delete':
                                      _deleteProfile(profile);
                                      break;
                                    case 'copy':
                                      _copyProfileConfig(profile);
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
                                    value: 'copy',
                                    child: ListTile(
                                      leading: Icon(Icons.copy),
                                      title: Text('Copy Config'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete),
                                      title: Text('Delete'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedProfile = profile;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getProtocolIcon(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'shadowsocks':
        return Icons.security;
      case 'vmess':
        return Icons.vpn_key;
      case 'trojan':
        return Icons.shield;
      case 'vless':
        return Icons.lock;
      case 'socks':
        return Icons.network_check;
      case 'http':
        return Icons.http;
      default:
        return Icons.router;
    }
  }

  void _showAddProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => ProfileDialog(
        onSave: (profile) {
          setState(() {
            _profiles.add(profile);
          });
        },
      ),
    );
  }

  void _showEditProfileDialog(ProxyProfile profile) {
    showDialog(
      context: context,
      builder: (context) => ProfileDialog(
        profile: profile,
        onSave: (updatedProfile) {
          setState(() {
            final index = _profiles.indexOf(profile);
            _profiles[index] = updatedProfile;
          });
        },
      ),
    );
  }

  void _deleteProfile(ProxyProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _profiles.remove(profile);
                if (_selectedProfile == profile) {
                  _selectedProfile = null;
                }
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _copyProfileConfig(ProxyProfile profile) {
    final config = profile.toJson();
    Clipboard.setData(ClipboardData(text: config));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration copied to clipboard')),
    );
  }
}

class ProxyProfile {
  final String id;
  final String name;
  final String protocol;
  final String server;
  final int port;
  final String? username;
  final String? password;
  final Map<String, dynamic> additionalSettings;

  ProxyProfile({
    required this.id,
    required this.name,
    required this.protocol,
    required this.server,
    required this.port,
    this.username,
    this.password,
    this.additionalSettings = const {},
  });

  String toJson() {
    // Generate a basic sing-box configuration
    return '''
{
  "outbounds": [
    {
      "type": "${protocol.toLowerCase()}",
      "tag": "$name",
      "server": "$server",
      "server_port": $port${username != null ? ',\n      "username": "$username"' : ''}${password != null ? ',\n      "password": "$password"' : ''}
    }
  ]
}''';
  }
}

class ProfileDialog extends StatefulWidget {
  final ProxyProfile? profile;
  final Function(ProxyProfile) onSave;

  const ProfileDialog({
    super.key,
    this.profile,
    required this.onSave,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _serverController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  
  String _selectedProtocol = 'Shadowsocks';
  final List<String> _protocols = [
    'Shadowsocks',
    'VMess',
    'Trojan',
    'VLESS',
    'SOCKS',
    'HTTP',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _serverController = TextEditingController(text: widget.profile?.server ?? '');
    _portController = TextEditingController(text: widget.profile?.port.toString() ?? '');
    _usernameController = TextEditingController(text: widget.profile?.username ?? '');
    _passwordController = TextEditingController(text: widget.profile?.password ?? '');
    
    if (widget.profile != null) {
      _selectedProtocol = widget.profile!.protocol;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.profile == null ? 'Add Profile' : 'Edit Profile'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Profile Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a profile name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedProtocol,
                decoration: const InputDecoration(
                  labelText: 'Protocol',
                  border: OutlineInputBorder(),
                ),
                items: _protocols.map((protocol) {
                  return DropdownMenuItem(
                    value: protocol,
                    child: Text(protocol),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProtocol = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'Server',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a server address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port number';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Please enter a valid port number (1-65535)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password (optional)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveProfile,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final profile = ProxyProfile(
        id: widget.profile?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        protocol: _selectedProtocol,
        server: _serverController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text.isEmpty ? null : _usernameController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
      );
      
      widget.onSave(profile);
      Navigator.of(context).pop();
    }
  }
}

