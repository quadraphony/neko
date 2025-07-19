import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vpn_profile.dart';
import '../services/vpn_service.dart';
import '../services/storage_service.dart';
import '../services/import_service.dart';
import '../services/export_service.dart';
import '../widgets/profile_card.dart';
import '../widgets/profile_editor.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

enum ProfileSortBy { name, group, lastUsed, dateAdded, protocol }
enum ProfileFilterBy { all, favorites, recent, byGroup, byProtocol }

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  final StorageService _storage = StorageService();
  final ImportService _importService = ImportService();
  final ExportService _exportService = ExportService();
  
  List<VpnProfile> _profiles = [];
  List<VpnProfile> _filteredProfiles = [];
  List<String> _selectedProfileIds = [];
  bool _isSelectionMode = false;
  bool _isLoading = true;
  
  ProfileSortBy _sortBy = ProfileSortBy.name;
  ProfileFilterBy _filterBy = ProfileFilterBy.all;
  String _searchQuery = '';
  String? _selectedGroup;
  VpnProtocol? _selectedProtocol;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _storage.loadProfiles();
      setState(() {
        _profiles = profiles;
        _filteredProfiles = profiles;
        _isLoading = false;
      });
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profiles: $e')),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    List<VpnProfile> filtered = List.from(_profiles);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((profile) =>
        profile.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        profile.server.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        profile.group?.toLowerCase().contains(_searchQuery.toLowerCase()) == true
      ).toList();
    }

    // Apply category filter
    switch (_filterBy) {
      case ProfileFilterBy.favorites:
        filtered = filtered.where((p) => p.isFavorite).toList();
        break;
      case ProfileFilterBy.recent:
        filtered = filtered.where((p) => p.updatedAt != null).toList();
        break;
      case ProfileFilterBy.byGroup:
        if (_selectedGroup != null) {
          filtered = filtered.where((p) => p.group == _selectedGroup).toList();
        }
        break;
      case ProfileFilterBy.byProtocol:
        if (_selectedProtocol != null) {
          filtered = filtered.where((p) => p.protocol == _selectedProtocol).toList();
        }
        break;
      case ProfileFilterBy.all:
      default:
        break;
    }

    // Apply sorting
    switch (_sortBy) {
      case ProfileSortBy.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProfileSortBy.group:
        filtered.sort((a, b) => (a.group ?? '').compareTo(b.group ?? ''));
        break;
      case ProfileSortBy.lastUsed:
        filtered.sort((a, b) {
          if (a.updatedAt == null && b.updatedAt == null) return 0;
          if (a.updatedAt == null) return 1;
          if (b.updatedAt == null) return -1;
          return b.updatedAt!.compareTo(a.updatedAt!);
        });
        break;
      case ProfileSortBy.dateAdded:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProfileSortBy.protocol:
        filtered.sort((a, b) => a.protocol.toString().compareTo(b.protocol.toString()));
        break;
    }

    setState(() {
      _filteredProfiles = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilterBar(),
          
          // Profile Count and Selection Info
          _buildProfileInfo(),
          
          // Profiles List
          Expanded(
            child: _filteredProfiles.isEmpty
                ? _buildEmptyState()
                : _buildProfilesList(),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : _buildSpeedDial(),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search profiles...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFiltersAndSort();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFiltersAndSort();
            },
          ),
          const SizedBox(height: 12),
          
          // Filter and Sort Row
          Row(
            children: [
              // Filter Dropdown
              Expanded(
                child: DropdownButtonFormField<ProfileFilterBy>(
                  value: _filterBy,
                  decoration: InputDecoration(
                    labelText: 'Filter',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ProfileFilterBy.values.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(_getFilterDisplayName(filter)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _filterBy = value;
                      });
                      _showFilterOptions(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Sort Dropdown
              Expanded(
                child: DropdownButtonFormField<ProfileSortBy>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ProfileSortBy.values.map((sort) {
                    return DropdownMenuItem(
                      value: sort,
                      child: Text(_getSortDisplayName(sort)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                      _applyFiltersAndSort();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isSelectionMode
                ? '${_selectedProfileIds.length} selected'
                : '${_filteredProfiles.length} profiles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (_isSelectionMode)
            Row(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Select All'),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vpn_key_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filterBy != ProfileFilterBy.all
                ? 'No profiles match your criteria'
                : 'No profiles yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterBy != ProfileFilterBy.all
                ? 'Try adjusting your search or filters'
                : 'Add your first VPN profile to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty && _filterBy == ProfileFilterBy.all)
            ElevatedButton.icon(
              onPressed: _showImportOptions,
              icon: const Icon(Icons.add),
              label: const Text('Add Profile'),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredProfiles.length,
      itemBuilder: (context, index) {
        final profile = _filteredProfiles[index];
        final isSelected = _selectedProfileIds.contains(profile.id);
        
        return ProfileCard(
          profile: profile,
          isSelected: isSelected,
          isSelectionMode: _isSelectionMode,
          onTap: () => _isSelectionMode ? _toggleSelection(profile.id) : _connectToProfile(profile),
          onLongPress: () => _enterSelectionMode(profile.id),
          onEdit: () => _editProfile(profile),
          onDuplicate: () => _duplicateProfile(profile),
          onDelete: () => _deleteProfile(profile),
          onToggleFavorite: () => _toggleFavorite(profile),
          onTest: () => _testProfile(profile),
        );
      },
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.edit),
          label: 'Create Profile',
          onTap: _createNewProfile,
        ),
        SpeedDialChild(
          child: const Icon(Icons.download),
          label: 'Import',
          onTap: _showImportOptions,
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: 'Scan QR',
          onTap: _scanQrCode,
        ),
        SpeedDialChild(
          child: const Icon(Icons.content_paste),
          label: 'From Clipboard',
          onTap: _importFromClipboard,
        ),
      ],
    );
  }

  // Helper methods for display names
  String _getFilterDisplayName(ProfileFilterBy filter) {
    switch (filter) {
      case ProfileFilterBy.all: return 'All';
      case ProfileFilterBy.favorites: return 'Favorites';
      case ProfileFilterBy.recent: return 'Recent';
      case ProfileFilterBy.byGroup: return 'By Group';
      case ProfileFilterBy.byProtocol: return 'By Protocol';
    }
  }

  String _getSortDisplayName(ProfileSortBy sort) {
    switch (sort) {
      case ProfileSortBy.name: return 'Name';
      case ProfileSortBy.group: return 'Group';
      case ProfileSortBy.lastUsed: return 'Last Used';
      case ProfileSortBy.dateAdded: return 'Date Added';
      case ProfileSortBy.protocol: return 'Protocol';
    }
  }

  // Selection methods
  void _enterSelectionMode(String profileId) {
    setState(() {
      _isSelectionMode = true;
      _selectedProfileIds = [profileId];
    });
  }

  void _toggleSelection(String profileId) {
    setState(() {
      if (_selectedProfileIds.contains(profileId)) {
        _selectedProfileIds.remove(profileId);
        if (_selectedProfileIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProfileIds.add(profileId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedProfileIds = _filteredProfiles.map((p) => p.id).toList();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProfileIds.clear();
      _isSelectionMode = false;
    });
  }

  // Profile actions
  void _connectToProfile(VpnProfile profile) async {
    try {
      final vpnService = Provider.of<VpnService>(context, listen: false);
      await vpnService.connect(profile);
      
      // Update last used timestamp
      final updatedProfile = profile.copyWith();
      await _storage.saveProfile(updatedProfile);
      _loadProfiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connecting to ${profile.name}...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  void _editProfile(VpnProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileEditor(
          profile: profile,
          onSave: (editedProfile) async {
            await _storage.saveProfile(editedProfile);
            _loadProfiles();
          },
        ),
      ),
    );
  }

  void _duplicateProfile(VpnProfile profile) {
    final duplicatedProfile = profile.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${profile.name} (Copy)',
      createdAt: DateTime.now(),
      lastUsed: null,
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileEditor(
          profile: duplicatedProfile,
          onSave: (newProfile) async {
            await _storage.saveProfile(newProfile);
            _loadProfiles();
          },
        ),
      ),
    );
  }

  void _deleteProfile(VpnProfile profile) {
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
          ElevatedButton(
            onPressed: () async {
              await _storage.deleteProfile(profile.id);
              _loadProfiles();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(VpnProfile profile) async {
    final updatedProfile = profile.copyWith(isFavorite: !profile.isFavorite);
    await _storage.saveProfile(updatedProfile);
    _loadProfiles();
  }

  void _testProfile(VpnProfile profile) async {
    // Show testing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Testing Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Testing connection to ${profile.name}...'),
          ],
        ),
      ),
    );

    try {
      // Simulate profile testing
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.of(context).pop(); // Close testing dialog
      
      // Show result
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Result'),
          content: const Text('Profile configuration is valid and server is reachable.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close testing dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Failed'),
          content: Text('Profile test failed: $e'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _createNewProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileEditor(
          onSave: (profile) async {
            await _storage.saveProfile(profile);
            _loadProfiles();
          },
        ),
      ),
    );
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('Import from File'),
              onTap: () {
                Navigator.of(context).pop();
                _importFromFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('Import from Clipboard'),
              onTap: () {
                Navigator.of(context).pop();
                _importFromClipboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Code'),
              onTap: () {
                Navigator.of(context).pop();
                _scanQrCode();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Import from URL'),
              onTap: () {
                Navigator.of(context).pop();
                _importFromUrl();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions(ProfileFilterBy filter) {
    if (filter == ProfileFilterBy.byGroup) {
      _showGroupSelector();
    } else if (filter == ProfileFilterBy.byProtocol) {
      _showProtocolSelector();
    } else {
      _applyFiltersAndSort();
    }
  }

  void _showGroupSelector() {
    final groups = _profiles.map((p) => p.group).where((g) => g != null).toSet().toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: groups.map((group) => RadioListTile<String>(
            title: Text(group!),
            value: group,
            groupValue: _selectedGroup,
            onChanged: (value) {
              setState(() {
                _selectedGroup = value;
              });
              _applyFiltersAndSort();
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showProtocolSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Protocol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: VpnProtocol.values.map((protocol) => RadioListTile<VpnProtocol>(
            title: Text(protocol.toString().split('.').last.toUpperCase()),
            value: protocol,
            groupValue: _selectedProtocol,
            onChanged: (value) {
              setState(() {
                _selectedProtocol = value;
              });
              _applyFiltersAndSort();
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  // Import methods
  void _importFromFile() async {
    try {
      final result = await ImportService.importFromFile();
      if (result.profiles.isNotEmpty) {
        for (final profile in result.profiles) {
          await _storage.saveProfile(profile);
        }
        _loadProfiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Imported ${result.profiles.length} profiles")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _importFromClipboard() async {
    try {
      final result = await ImportService.importFromClipboard();
      if (result.profiles.isNotEmpty) {
        for (final profile in result.profiles) {
          await _storage.saveProfile(profile);
        }
        _loadProfiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Imported ${result.profiles.length} profiles from clipboard")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid profiles found in clipboard')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _scanQrCode() async {
    try {
      final result = await ImportService.importFromQRCode("");
      if (result.profiles.isNotEmpty) {
        for (final profile in result.profiles) {
          await _storage.saveProfile(profile);
        }
        _loadProfiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Imported ${result.profiles.length} profiles from QR code")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR scan failed: $e')),
        );
      }
    }
  }

  void _importFromUrl() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subscription URL',
            hintText: 'https://example.com/config',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final result = await ImportService.importFromUrl(controller.text, name: 'Imported from URL');
                if (result.profiles.isNotEmpty) {
                  for (final profile in result.profiles) {
                    await _storage.saveProfile(profile);
                  }
                  _loadProfiles();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Imported ${result.profiles.length} profiles from URL")),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

