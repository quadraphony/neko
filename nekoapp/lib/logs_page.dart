import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  LogLevel _selectedLogLevel = LogLevel.all;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _generateSampleLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _generateSampleLogs() {
    // Generate some sample log entries for demonstration
    final sampleLogs = [
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        level: LogLevel.info,
        message: 'NekoBox core initialized successfully',
      ),
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        level: LogLevel.info,
        message: 'Loading proxy configuration',
      ),
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        level: LogLevel.warning,
        message: 'DNS resolution took longer than expected',
      ),
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        level: LogLevel.info,
        message: 'Proxy connection established',
      ),
      LogEntry(
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        level: LogLevel.debug,
        message: 'Traffic stats updated: 1.2MB up, 5.4MB down',
      ),
    ];

    setState(() {
      _logs.addAll(sampleLogs);
    });
  }

  List<LogEntry> get _filteredLogs {
    if (_selectedLogLevel == LogLevel.all) {
      return _logs;
    }
    return _logs.where((log) => log.level == _selectedLogLevel).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _filteredLogs;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with controls
          Row(
            children: [
              Text(
                'Logs',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              // Log level filter
              DropdownButton<LogLevel>(
                value: _selectedLogLevel,
                items: LogLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLogLevel = value!;
                  });
                },
              ),
              const SizedBox(width: 8),
              // Auto-scroll toggle
              IconButton(
                onPressed: () {
                  setState(() {
                    _autoScroll = !_autoScroll;
                  });
                },
                icon: Icon(
                  _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
                ),
                tooltip: _autoScroll ? 'Disable auto-scroll' : 'Enable auto-scroll',
              ),
              // Clear logs
              IconButton(
                onPressed: _clearLogs,
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear logs',
              ),
              // Export logs
              IconButton(
                onPressed: _exportLogs,
                icon: const Icon(Icons.download),
                tooltip: 'Export logs',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Logs list
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No logs available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Logs will appear here when the proxy is active',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : Card(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return LogEntryWidget(
                          log: log,
                          onTap: () => _showLogDetails(log),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _logs.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportLogs() {
    final logsText = _logs.map((log) => log.toString()).join('\n');
    Clipboard.setData(ClipboardData(text: logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void _showLogDetails(LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${log.formattedTimestamp}'),
            const SizedBox(height: 8),
            Text('Level: ${log.level.displayName}'),
            const SizedBox(height: 8),
            Text('Message:'),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                log.message,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: log.toString()));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Log entry copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

enum LogLevel {
  all('All'),
  debug('Debug'),
  info('Info'),
  warning('Warning'),
  error('Error');

  const LogLevel(this.displayName);
  final String displayName;
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  Color getColor(BuildContext context) {
    switch (level) {
      case LogLevel.debug:
        return Theme.of(context).colorScheme.outline;
      case LogLevel.info:
        return Theme.of(context).colorScheme.primary;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Theme.of(context).colorScheme.error;
      case LogLevel.all:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  IconData getIcon() {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
      case LogLevel.all:
        return Icons.list;
    }
  }

  @override
  String toString() {
    return '[$formattedTimestamp] ${level.displayName.toUpperCase()}: $message';
  }
}

class LogEntryWidget extends StatelessWidget {
  final LogEntry log;
  final VoidCallback? onTap;

  const LogEntryWidget({
    super.key,
    required this.log,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              log.getIcon(),
              size: 16,
              color: log.getColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              log.formattedTimestamp,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                log.message,
                style: TextStyle(
                  fontSize: 14,
                  color: log.getColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

