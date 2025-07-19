import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vpn_service.dart';

enum LogLevelFilter { all, debug, info, warning, error }

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scrollController = ScrollController();
  LogLevelFilter _logLevelFilter = LogLevelFilter.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Automatically scroll to the bottom when new logs arrive
    Provider.of<VpnService>(context, listen: false).addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnService>(
      builder: (context, vpnService, child) {
        final filteredLogs = vpnService.getFilteredLogs(
          level: _logLevelFilter.toString().split('.').last.toUpperCase(),
          search: _searchController.text,
        );

        return Column(
          children: [
            _buildLogControls(),
            Expanded(
              child: filteredLogs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final logEntry = filteredLogs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              logEntry.message,
                              style: TextStyle(
                                fontSize: 12.0,
                                color: _getLogColor(logEntry.message),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search logs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<LogLevelFilter>(
                value: _logLevelFilter,
                onChanged: (LogLevelFilter? newValue) {
                  setState(() {
                    _logLevelFilter = newValue!;
                  });
                },
                items: LogLevelFilter.values.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Text(filter.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Provider.of<VpnService>(context, listen: false).clearLogs();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Logs'),
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
            Icons.info_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No logs to display',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to a VPN or adjust filters to see logs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String logEntry) {
    if (logEntry.toLowerCase().contains('error') || logEntry.toLowerCase().contains('fatal')) {
      return Colors.red;
    } else if (logEntry.toLowerCase().contains('warning')) {
      return Colors.orange;
    } else if (logEntry.toLowerCase().contains('info')) {
      return Colors.blue;
    } else if (logEntry.toLowerCase().contains('debug') || logEntry.toLowerCase().contains('trace')) {
      return Colors.grey;
    } else {
      return Colors.black;
    }
  }
}

