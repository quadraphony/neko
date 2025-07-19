import 'package:flutter/material.dart';
import '../models/vpn_profile.dart';

class ProfileEditor extends StatefulWidget {
  final VpnProfile? profile;
  final Function(VpnProfile) onSave;

  const ProfileEditor({
    super.key,
    this.profile,
    required this.onSave,
  });

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _groupController = TextEditingController();
  final _remarksController = TextEditingController();

  VpnProtocol _selectedProtocol = VpnProtocol.vmess;
  bool _isFavorite = false;
  Map<String, dynamic> _protocolSettings = {};

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _loadProfile(widget.profile!);
    } else {
      _setDefaultValues();
    }
  }

  void _loadProfile(VpnProfile profile) {
    _nameController.text = profile.name;
    _serverController.text = profile.server;
    _portController.text = profile.port.toString();
    _usernameController.text = profile.username ?? "";
    _passwordController.text = profile.password ?? "";
    _groupController.text = profile.group ?? "";
    _remarksController.text = profile.remarks ?? "";
    _selectedProtocol = profile.protocol;
    _isFavorite = profile.isFavorite;
    _protocolSettings = Map.from(profile.protocolSettings);
  }

  void _setDefaultValues() {
    _portController.text = "443";
    _protocolSettings = _getDefaultProtocolSettings(_selectedProtocol);
  }

  Map<String, dynamic> _getDefaultProtocolSettings(VpnProtocol protocol) {
    switch (protocol) {
      case VpnProtocol.vmess:
        return {
          "uuid": "",
          "alterId": 0,
          "security": "auto",
          "network": "tcp",
          "headerType": "none",
          "path": "/",
          "host": "",
          "tls": false,
        };
      case VpnProtocol.vless:
        return {
          "uuid": "",
          "flow": "",
          "encryption": "none",
          "network": "tcp",
          "headerType": "none",
          "path": "/",
          "host": "",
          "tls": false,
        };
      case VpnProtocol.trojan:
        return {
          "password": "",
          "sni": "",
          "alpn": "",
          "allowInsecure": false,
        };
      case VpnProtocol.shadowsocks:
        return {
          "method": "aes-256-gcm",
          "password": "",
          "plugin": "",
          "pluginOpts": "",
        };
      case VpnProtocol.wireguard:
        return {
          "privateKey": "",
          "publicKey": "",
          "preSharedKey": "",
          "endpoint": "",
          "allowedIPs": "0.0.0.0/0",
          "mtu": 1420,
        };
      case VpnProtocol.hysteria:
        return {
          "protocol": "udp",
          "auth": "",
          "alpn": "h3",
          "obfs": "",
          "upMbps": 10,
          "downMbps": 50,
        };
      case VpnProtocol.hysteria2:
        return {
          "password": "",
          "obfs": "",
          "obfsPassword": "",
          "sni": "",
          "insecure": false,
        };
      case VpnProtocol.tuic:
        return {
          "uuid": "",
          "password": "",
          "congestionControl": "cubic",
          "alpn": "h3",
          "sni": "",
        };
      case VpnProtocol.socks:
        return {
          "version": "5",
          "username": "",
          "password": "",
        };
      case VpnProtocol.http:
        return {
          "username": "",
          "password": "",
          "tls": false,
        };
      case VpnProtocol.ssh:
        return {
          "username": "",
          "password": "",
          "privateKey": "",
          "hostKey": "",
        };
      case VpnProtocol.naiveProxy:
        return {
          "username": "",
          "password": "",
          "extraHeaders": {},
        };
      case VpnProtocol.naive:
        return {
          "username": "",
          "password": "",
          "extraHeaders": {},
        };
      case VpnProtocol.brook:
        return {
          "password": "",
          "udpOverTcp": false,
        };
      case VpnProtocol.snell:
        return {
          "psk": "",
          "version": "4",
          "obfs": "tls",
        };
      case VpnProtocol.mieru:
        return {
          "username": "",
          "password": "",
          "domainName": "",
        };
      case VpnProtocol.trojanGo:
        return {
          "password": "",
          "sni": "",
          "alpn": "",
          "allowInsecure": false,
        };
      case VpnProtocol.anyTls:
        return {}; // No specific settings for anyTls
      case VpnProtocol.shadowTls:
        return {}; // No specific settings for shadowTls
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            _buildTextField(
              controller: _nameController,
              label: 'Profile Name',
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _groupController,
              label: 'Group (Optional)',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _remarksController,
              label: 'Remarks (Optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Add to Favorites'),
              value: _isFavorite,
              onChanged: (value) => setState(() => _isFavorite = value),
            ),

            const SizedBox(height: 24),

            // Server Information Section
            _buildSectionHeader('Server Information'),
            _buildTextField(
              controller: _serverController,
              label: 'Server Address',
              validator: (value) => value?.isEmpty == true ? 'Server address is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _portController,
              label: 'Port',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Port is required';
                final port = int.tryParse(value!);
                if (port == null || port < 1 || port > 65535) {
                  return 'Invalid port number';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Protocol Section
            _buildSectionHeader('Protocol Configuration'),
            DropdownButtonFormField<VpnProtocol>(
              value: _selectedProtocol,
              decoration: const InputDecoration(
                labelText: 'Protocol',
                border: OutlineInputBorder(),
              ),
              items: VpnProtocol.values.map((protocol) {
                return DropdownMenuItem(
                  value: protocol,
                  child: Text(protocol.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedProtocol = value;
                    _protocolSettings = _getDefaultProtocolSettings(value);
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Protocol-specific settings
            _buildProtocolSettings(),

            const SizedBox(height: 24),

            // Authentication Section (if needed)
            if (_needsAuthentication())
              _buildAuthenticationSection(),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
    );
  }

  Widget _buildProtocolSettings() {
    switch (_selectedProtocol) {
      case VpnProtocol.vmess:
        return _buildVMessSettings();
      case VpnProtocol.vless:
        return _buildVLessSettings();
      case VpnProtocol.trojan:
        return _buildTrojanSettings();
      case VpnProtocol.shadowsocks:
        return _buildShadowsocksSettings();
      case VpnProtocol.wireguard:
        return _buildWireGuardSettings();
      case VpnProtocol.hysteria:
        return _buildHysteriaSettings();
      case VpnProtocol.hysteria2:
        return _buildHysteria2Settings();
      case VpnProtocol.tuic:
        return _buildTuicSettings();
      default:
        return _buildGenericSettings();
    }
  }

  Widget _buildVMessSettings() {
    return Column(
      children: [
        _buildProtocolTextField('uuid', 'UUID'),
        const SizedBox(height: 16),
        _buildProtocolDropdown('security', 'Security', ['auto', 'aes-128-gcm', 'chacha20-poly1305', 'none']),
        const SizedBox(height: 16),
        _buildProtocolDropdown('network', 'Network', ['tcp', 'kcp', 'ws', 'http', 'quic', 'grpc']),
        const SizedBox(height: 16),
        _buildProtocolTextField('path', 'Path'),
        const SizedBox(height: 16),
        _buildProtocolTextField('host', 'Host'),
        const SizedBox(height: 16),
        _buildProtocolSwitch('tls', 'Enable TLS'),
      ],
    );
  }

  Widget _buildVLessSettings() {
    return Column(
      children: [
        _buildProtocolTextField('uuid', 'UUID'),
        const SizedBox(height: 16),
        _buildProtocolTextField('flow', 'Flow'),
        const SizedBox(height: 16),
        _buildProtocolDropdown('network', 'Network', ['tcp', 'kcp', 'ws', 'http', 'quic', 'grpc']),
        const SizedBox(height: 16),
        _buildProtocolTextField('path', 'Path'),
        const SizedBox(height: 16),
        _buildProtocolTextField('host', 'Host'),
        const SizedBox(height: 16),
        _buildProtocolSwitch('tls', 'Enable TLS'),
      ],
    );
  }

  Widget _buildTrojanSettings() {
    return Column(
      children: [
        _buildProtocolTextField('password', 'Password', obscureText: true),
        const SizedBox(height: 16),
        _buildProtocolTextField('sni', 'SNI'),
        const SizedBox(height: 16),
        _buildProtocolTextField('alpn', 'ALPN'),
        const SizedBox(height: 16),
        _buildProtocolSwitch('allowInsecure', 'Allow Insecure'),
      ],
    );
  }

  Widget _buildShadowsocksSettings() {
    return Column(
      children: [
        _buildProtocolDropdown('method', 'Encryption Method', [
          'aes-256-gcm', 'aes-128-gcm', 'chacha20-ietf-poly1305', 'xchacha20-ietf-poly1305'
        ]),
        const SizedBox(height: 16),
        _buildProtocolTextField('password', 'Password', obscureText: true),
        const SizedBox(height: 16),
        _buildProtocolTextField('plugin', 'Plugin'),
        const SizedBox(height: 16),
        _buildProtocolTextField('pluginOpts', 'Plugin Options'),
      ],
    );
  }

  Widget _buildWireGuardSettings() {
    return Column(
      children: [
        _buildProtocolTextField('privateKey', 'Private Key'),
        const SizedBox(height: 16),
        _buildProtocolTextField('publicKey', 'Public Key'),
        const SizedBox(height: 16),
        _buildProtocolTextField('preSharedKey', 'Pre-shared Key'),
        const SizedBox(height: 16),
        _buildProtocolTextField('allowedIPs', 'Allowed IPs'),
        const SizedBox(height: 16),
        _buildProtocolTextField('mtu', 'MTU', keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildHysteriaSettings() {
    return Column(
      children: [
        _buildProtocolTextField('auth', 'Auth'),
        const SizedBox(height: 16),
        _buildProtocolTextField('obfs', 'Obfuscation'),
        const SizedBox(height: 16),
        _buildProtocolTextField('upMbps', 'Upload Speed (Mbps)', keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildProtocolTextField('downMbps', 'Download Speed (Mbps)', keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildHysteria2Settings() {
    return Column(
      children: [
        _buildProtocolTextField('password', 'Password', obscureText: true),
        const SizedBox(height: 16),
        _buildProtocolTextField('obfs', 'Obfuscation'),
        const SizedBox(height: 16),
        _buildProtocolTextField('obfsPassword', 'Obfuscation Password', obscureText: true),
        const SizedBox(height: 16),
        _buildProtocolTextField('sni', 'SNI'),
        const SizedBox(height: 16),
        _buildProtocolSwitch('insecure', 'Allow Insecure'),
      ],
    );
  }

  Widget _buildTuicSettings() {
    return Column(
      children: [
        _buildProtocolTextField('uuid', 'UUID'),
        const SizedBox(height: 16),
        _buildProtocolTextField('password', 'Password', obscureText: true),
        const SizedBox(height: 16),
        _buildProtocolDropdown('congestionControl', 'Congestion Control', ['cubic', 'new_reno', 'bbr']),
        const SizedBox(height: 16),
        _buildProtocolTextField('sni', 'SNI'),
      ],
    );
  }

  Widget _buildGenericSettings() {
    return Column(
      children: [
        _buildProtocolTextField('username', 'Username'),
        const SizedBox(height: 16),
        _buildProtocolTextField('password', 'Password', obscureText: true),
      ],
    );
  }

  Widget _buildProtocolTextField(String key, String label, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      initialValue: _protocolSettings[key]?.toString() ?? '',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: (value) {
        setState(() {
          if (keyboardType == TextInputType.number) {
            _protocolSettings[key] = int.tryParse(value) ?? 0;
          } else {
            _protocolSettings[key] = value;
          }
        });
      },
    );
  }

  Widget _buildProtocolDropdown(String key, String label, List<String> options) {
    return DropdownButtonFormField<String>(
      value: _protocolSettings[key]?.toString(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _protocolSettings[key] = value;
        });
      },
    );
  }

  Widget _buildProtocolSwitch(String key, String label) {
    return SwitchListTile(
      title: Text(label),
      value: _protocolSettings[key] == true,
      onChanged: (value) {
        setState(() {
          _protocolSettings[key] = value;
        });
      },
    );
  }

  bool _needsAuthentication() {
    return [
      VpnProtocol.socks,
      VpnProtocol.http,
      VpnProtocol.ssh,
      VpnProtocol.naive,
    ].contains(_selectedProtocol);
  }

  Widget _buildAuthenticationSection() {
    return Column(
      children: [
        _buildSectionHeader('Authentication'),
        _buildTextField(
          controller: _usernameController,
          label: 'Username',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          obscureText: true,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() == true) {
      final profile = VpnProfile(
        id: widget.profile?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        server: _serverController.text,
        port: int.parse(_portController.text),
        protocol: _selectedProtocol,
        username: _usernameController.text.isEmpty ? null : _usernameController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        group: _groupController.text.isEmpty ? null : _groupController.text,
        remarks: _remarksController.text.isEmpty ? null : _remarksController.text,
        isFavorite: _isFavorite,
        protocolSettings: _protocolSettings,
        createdAt: widget.profile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: widget.profile?.isActive ?? false,
      );

      widget.onSave(profile);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _groupController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}

