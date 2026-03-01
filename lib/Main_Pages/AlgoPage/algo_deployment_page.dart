import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optionxi/Main_Pages/AlgoPage/algo_page_v2.dart';

class AlgoDeploymentPage extends StatefulWidget {
  const AlgoDeploymentPage({Key? key}) : super(key: key);

  @override
  State<AlgoDeploymentPage> createState() => _AlgoDeploymentPageState();
}

class _AlgoDeploymentPageState extends State<AlgoDeploymentPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _deployedAlgos = [];

  @override
  void initState() {
    super.initState();
    _loadDeployedAlgos();
  }

  Future<void> _loadDeployedAlgos() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      final response = await http.get(
        // Uri.parse('https://algo.optionxi.com/algos'),
        Uri.parse('http://localhost:8000/algos'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _deployedAlgos = List<Map<String, dynamic>>.from(
            jsonDecode(response.body)['algos'] ?? [],
          );
        });
      }
    } catch (e) {
      _showSnackBar('Error loading algos: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAlgoStatus(String algoId, bool currentStatus) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      final response = await http.patch(
        Uri.parse('https://algo.optionxi.com/algos/$algoId/toggle'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _loadDeployedAlgos();
        _showSnackBar('Algo ${!currentStatus ? 'activated' : 'deactivated'}');
      }
    } catch (e) {
      _showSnackBar('Error updating algo: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade900 : Colors.green.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 160,
            backgroundColor: isDark ? const Color(0xFF0F1420) : Colors.white,
            elevation: 0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Algo Strategies',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0F1420), const Color(0xFF1A2332)]
                        : [Colors.white, const Color(0xFFF0F4F8)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 100, left: 24, right: 24),
                  child: Row(
                    children: [
                      _StatCard(
                        label: 'Active',
                        value: _deployedAlgos
                            .where((a) => a['is_active'] == true)
                            .length
                            .toString(),
                        icon: Icons.play_circle_outline,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Total',
                        value: _deployedAlgos.length.toString(),
                        icon: Icons.auto_graph,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: _isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                : _deployedAlgos.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_graph_outlined,
                                size: 80,
                                color: colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No strategies deployed yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first algo strategy to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final algo = _deployedAlgos[index];
                            return _AlgoCard(
                              algo: algo,
                              onToggle: () => _toggleAlgoStatus(
                                algo['id'],
                                algo['is_active'] ?? false,
                              ),
                            );
                          },
                          childCount: _deployedAlgos.length,
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AlgoPageV2(),
            ),
          );
          if (result == true) {
            _loadDeployedAlgos();
          }
        },
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'New Strategy',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlgoCard extends StatelessWidget {
  final Map<String, dynamic> algo;
  final VoidCallback onToggle;

  const _AlgoCard({
    required this.algo,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = algo['is_active'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : (isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05)),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color:
                                        isActive ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isActive ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            algo['name'] ?? 'Unnamed Strategy',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoChip(
                        icon: Icons.input,
                        label: algo['entry_type'] ?? 'N/A',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (_) => onToggle(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'Option Type',
                        value: algo['option_type'] ?? 'N/A',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Lot Size',
                        value: algo['lot_size']?.toString() ?? 'N/A',
                        icon: Icons.format_list_numbered,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DetailItem(
                        label: 'Exit Type',
                        value: algo['exit_type'] ?? 'N/A',
                        icon: Icons.exit_to_app,
                      ),
                    ),
                    Expanded(
                      child: _DetailItem(
                        label: 'Created',
                        value: _formatDate(algo['created_at']),
                        icon: Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
