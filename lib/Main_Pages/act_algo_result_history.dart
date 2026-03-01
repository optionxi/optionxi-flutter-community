import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Main_Pages/act_algo_result.dart';

class BacktestHistoryPage extends StatefulWidget {
  const BacktestHistoryPage({Key? key}) : super(key: key);

  @override
  State<BacktestHistoryPage> createState() => _BacktestHistoryPageState();
}

class _BacktestHistoryPageState extends State<BacktestHistoryPage> {
  final FirebaseDatabase db = FirebaseDatabase.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  List<BacktestHistoryItem> historyItems = [];
  bool isLoading = true;
  String filterStatus = 'all'; // all, completed, error, running

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => isLoading = true);
    try {
      // Load from backtest_queue to get all attempts
      final queueSnap = await db.ref('backtest_queue/$uid').get();

      List<BacktestHistoryItem> items = [];

      if (queueSnap.exists) {
        final queueData = queueSnap.value as Map;

        for (var entry in queueData.entries) {
          final algoId = entry.key;
          final data = entry.value as Map;

          // Get algo name from algo collection
          final algoSnap = await db.ref('algo/$uid/$algoId').get();
          String algoName = 'Unnamed Strategy';
          if (algoSnap.exists) {
            final algoData = algoSnap.value as Map;
            algoName = algoData['name'] ?? algoName;
          }

          items.add(BacktestHistoryItem(
            algoId: algoId,
            algoName: algoName,
            status: data['status'] ?? 'unknown',
            timestamp:
                data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            message: data['message'],
          ));
        }
      }

      // Sort by timestamp descending (newest first)
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        historyItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error loading history: $e', isError: true);
    }
  }

  List<BacktestHistoryItem> get filteredItems {
    if (filterStatus == 'all') return historyItems;
    return historyItems.where((item) => item.status == filterStatus).toList();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backtest History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', _getStatusCount('all')),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Completed', 'completed', _getStatusCount('completed')),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Running', 'running', _getStatusCount('running')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Error', 'error', _getStatusCount('error')),
                ],
              ),
            ),
          ),

          // History List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(
                                filteredItems[index], cardColor);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = filterStatus == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : (isDark ? Colors.grey[700] : Colors.grey[300]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => filterStatus = value);
      },
      selectedColor: Colors.indigoAccent,
      checkmarkColor: Colors.white,
    );
  }

  int _getStatusCount(String status) {
    if (status == 'all') return historyItems.length;
    return historyItems.where((item) => item.status == status).length;
  }

  Widget _buildHistoryCard(BacktestHistoryItem item, Color? cardColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'running':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'queued':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (item.status == 'completed' ||
              item.status == 'running' ||
              item.status == 'queued') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BacktestResultPage(
                  algoId: item.algoId,
                  algoName: item.algoName,
                ),
              ),
            ).then((_) => _loadHistory()); // Refresh on return
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status Indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Strategy Name and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.algoName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow Icon
                  if (item.status == 'completed' ||
                      item.status == 'running' ||
                      item.status == 'queued')
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Timestamp
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(item.timestamp),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Error Message (if any)
              if (item.message != null && item.status == 'error') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.message!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[300],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            filterStatus == 'all'
                ? 'No Backtests Yet'
                : 'No ${filterStatus.capitalize()} Backtests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            filterStatus == 'all'
                ? 'Run your first backtest to see it here'
                : 'Try a different filter',
            style: TextStyle(
              color: isDark ? Colors.grey[700] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy • HH:mm').format(dt);
    }
  }
}

class BacktestHistoryItem {
  final String algoId;
  final String algoName;
  final String status;
  final int timestamp;
  final String? message;

  BacktestHistoryItem({
    required this.algoId,
    required this.algoName,
    required this.status,
    required this.timestamp,
    this.message,
  });
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
