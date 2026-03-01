import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class AlgoPageV2 extends StatefulWidget {
  const AlgoPageV2({Key? key}) : super(key: key);

  @override
  State<AlgoPageV2> createState() => _AlgoPageV2State();
}

class _AlgoPageV2State extends State<AlgoPageV2>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isSubmitting = false;

  // Form data
  final TextEditingController _nameController = TextEditingController();

  // Entry Condition
  String _entryType = 'range_breakout';
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 15);
  TimeOfDay _toTime = const TimeOfDay(hour: 15, minute: 30);
  String _breakoutDirection = 'high';
  String _previousBreakoutType = 'previous_high';
  String _currentBreakoutType = 'current_high';
  double _aiProbability = 70.0;
  String _aiBreakoutType = 'day_high';

  // Buy What
  String _optionType = 'ATM';
  final TextEditingController _rangeMinController = TextEditingController();
  final TextEditingController _rangeMaxController = TextEditingController();
  int _lotSize = 1;

  // Exit Condition
  String _exitType = 'target_sl_points';
  final TextEditingController _targetPointsController = TextEditingController();
  final TextEditingController _slPointsController = TextEditingController();
  final TextEditingController _targetPercentController =
      TextEditingController();
  final TextEditingController _slPercentController = TextEditingController();
  int _smaValue = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _rangeMinController.dispose();
    _rangeMaxController.dispose();
    _targetPointsController.dispose();
    _slPointsController.dispose();
    _targetPercentController.dispose();
    _slPercentController.dispose();
    super.dispose();
  }

  Future<void> _submitAlgo() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('User not authenticated', isError: true);
        return;
      }

      final token = await user.getIdToken();

      final algoData = {
        'name': _nameController.text,
        'entry_type': _entryType,
        'entry_config': _buildEntryConfig(),
        'option_type': _optionType,
        'option_config': _buildOptionConfig(),
        'lot_size': _lotSize,
        'exit_type': _exitType,
        'exit_config': _buildExitConfig(),
      };

      final response = await http.post(
        Uri.parse('https://algo.optionxi.com/algos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(algoData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Algo strategy created successfully!');
        Navigator.pop(context, true);
      } else {
        _showSnackBar('Failed to create algo: ${response.body}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Map<String, dynamic> _buildEntryConfig() {
    switch (_entryType) {
      case 'range_breakout':
        return {
          'from_time':
              '${_fromTime.hour.toString().padLeft(2, '0')}:${_fromTime.minute.toString().padLeft(2, '0')}',
          'to_time':
              '${_toTime.hour.toString().padLeft(2, '0')}:${_toTime.minute.toString().padLeft(2, '0')}',
          'breakout_direction': _breakoutDirection,
        };
      case 'previous_breakout':
        return {
          'previous_type': _previousBreakoutType,
          'current_type': _currentBreakoutType,
        };
      case 'ai_probability':
        return {
          'probability_threshold': _aiProbability,
          'breakout_type': _aiBreakoutType,
        };
      default:
        return {};
    }
  }

  Map<String, dynamic> _buildOptionConfig() {
    if (_optionType == 'Range') {
      return {
        'min': double.tryParse(_rangeMinController.text) ?? 0,
        'max': double.tryParse(_rangeMaxController.text) ?? 1000,
      };
    }
    return {};
  }

  Map<String, dynamic> _buildExitConfig() {
    switch (_exitType) {
      case 'target_sl_points':
        return {
          'target_points': double.tryParse(_targetPointsController.text) ?? 0,
          'sl_points': double.tryParse(_slPointsController.text) ?? 0,
        };
      case 'target_sl_percent':
        return {
          'target_percent': double.tryParse(_targetPercentController.text) ?? 0,
          'sl_percent': double.tryParse(_slPercentController.text) ?? 0,
        };
      case 'sma_based':
        return {
          'sma_value': _smaValue,
        };
      default:
        return {};
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
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F1420) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create New Strategy',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              color: isDark ? const Color(0xFF0F1420) : Colors.white,
              padding: const EdgeInsets.all(20),
              child: TextFormField(
                controller: _nameController,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Strategy Name',
                  hintText: 'Enter a name for your strategy',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1A2332)
                      : const Color(0xFFF5F7FA),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a strategy name';
                  }
                  return null;
                },
              ),
            ),
            Container(
              color: isDark ? const Color(0xFF0F1420) : Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 3,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'ENTRY'),
                  Tab(text: 'BUY'),
                  Tab(text: 'EXIT'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEntryConditionTab(isDark),
                  _buildBuyWhatTab(isDark),
                  _buildExitConditionTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1420) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_tabController.index > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _tabController.animateTo(_tabController.index - 1);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: colorScheme.primary),
                    ),
                    child: const Text(
                      'Previous',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              if (_tabController.index > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (_tabController.index < 2) {
                            _tabController.animateTo(_tabController.index + 1);
                          } else {
                            _submitAlgo();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _tabController.index < 2 ? 'Next' : 'Create Strategy',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryConditionTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          isDark: isDark,
          title: 'Entry Condition Type',
          child: Column(
            children: [
              _RadioOption(
                value: 'range_breakout',
                groupValue: _entryType,
                title: 'Range Breakout',
                subtitle: 'Time-based range with high/low breakout',
                icon: Icons.trending_up,
                onChanged: (value) => setState(() => _entryType = value!),
              ),
              const SizedBox(height: 12),
              _RadioOption(
                value: 'previous_breakout',
                groupValue: _entryType,
                title: 'Previous/Current Breakout',
                subtitle: 'Based on previous and current high/low',
                icon: Icons.show_chart,
                onChanged: (value) => setState(() => _entryType = value!),
              ),
              const SizedBox(height: 12),
              _RadioOption(
                value: 'ai_probability',
                groupValue: _entryType,
                title: 'AI Probability Indicator',
                subtitle: 'AI-based with day high/low breakout',
                icon: Icons.psychology,
                onChanged: (value) => setState(() => _entryType = value!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_entryType == 'range_breakout') _buildRangeBreakoutConfig(isDark),
        if (_entryType == 'previous_breakout')
          _buildPreviousBreakoutConfig(isDark),
        if (_entryType == 'ai_probability') _buildAIProbabilityConfig(isDark),
      ],
    );
  }

  Widget _buildRangeBreakoutConfig(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Configuration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TimeSelector(
                  label: 'From Time',
                  time: _fromTime,
                  onSelect: (time) => setState(() => _fromTime = time),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeSelector(
                  label: 'To Time',
                  time: _toTime,
                  onSelect: (time) => setState(() => _toTime = time),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Breakout Direction',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ChoiceChip(
                  label: 'High',
                  icon: Icons.arrow_upward,
                  selected: _breakoutDirection == 'high',
                  onSelected: () => setState(() => _breakoutDirection = 'high'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceChip(
                  label: 'Low',
                  icon: Icons.arrow_downward,
                  selected: _breakoutDirection == 'low',
                  onSelected: () => setState(() => _breakoutDirection = 'low'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousBreakoutConfig(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Configuration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Previous Breakout Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ChoiceChip(
                  label: 'Prev High',
                  selected: _previousBreakoutType == 'previous_high',
                  onSelected: () =>
                      setState(() => _previousBreakoutType = 'previous_high'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceChip(
                  label: 'Prev Low',
                  selected: _previousBreakoutType == 'previous_low',
                  onSelected: () =>
                      setState(() => _previousBreakoutType = 'previous_low'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Current Breakout Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ChoiceChip(
                  label: 'Current High',
                  selected: _currentBreakoutType == 'current_high',
                  onSelected: () =>
                      setState(() => _currentBreakoutType = 'current_high'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceChip(
                  label: 'Current Low',
                  selected: _currentBreakoutType == 'current_low',
                  onSelected: () =>
                      setState(() => _currentBreakoutType = 'current_low'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIProbabilityConfig(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Configuration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Probability Threshold: ${_aiProbability.toInt()}%',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _aiProbability,
            min: 50,
            max: 95,
            divisions: 9,
            label: '${_aiProbability.toInt()}%',
            onChanged: (value) => setState(() => _aiProbability = value),
          ),
          const SizedBox(height: 16),
          const Text(
            'Breakout Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ChoiceChip(
                  label: 'Day High',
                  selected: _aiBreakoutType == 'day_high',
                  onSelected: () =>
                      setState(() => _aiBreakoutType = 'day_high'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceChip(
                  label: 'Day Low',
                  selected: _aiBreakoutType == 'day_low',
                  onSelected: () => setState(() => _aiBreakoutType = 'day_low'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuyWhatTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          isDark: isDark,
          title: 'Option Type',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChip(
                      label: 'ATM',
                      selected: _optionType == 'ATM',
                      onSelected: () => setState(() => _optionType = 'ATM'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChoiceChip(
                      label: 'OTM',
                      selected: _optionType == 'OTM',
                      onSelected: () => setState(() => _optionType = 'OTM'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChip(
                      label: 'ITM',
                      selected: _optionType == 'ITM',
                      onSelected: () => setState(() => _optionType = 'ITM'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChoiceChip(
                      label: 'Range',
                      selected: _optionType == 'Range',
                      onSelected: () => setState(() => _optionType = 'Range'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_optionType == 'Range') ...[
          const SizedBox(height: 16),
          _SectionCard(
            isDark: isDark,
            title: 'Price Range',
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rangeMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Amount',
                      prefixText: '₹',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (_optionType == 'Range' &&
                          (value == null || value.isEmpty)) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _rangeMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Amount',
                      prefixText: '₹',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (_optionType == 'Range' &&
                          (value == null || value.isEmpty)) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _SectionCard(
          isDark: isDark,
          title: 'Lot Size',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lots: $_lotSize',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _lotSize.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$_lotSize',
                onChanged: (value) => setState(() => _lotSize = value.toInt()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 Lot',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '10 Lots',
                    style: TextStyle(
                      fontSize: 12,
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
      ],
    );
  }

  Widget _buildExitConditionTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          isDark: isDark,
          title: 'Exit Condition Type',
          child: Column(
            children: [
              _RadioOption(
                value: 'target_sl_points',
                groupValue: _exitType,
                title: 'Target/SL Points',
                subtitle: 'Exit based on absolute points',
                icon: Icons.pin_drop,
                onChanged: (value) => setState(() => _exitType = value!),
              ),
              const SizedBox(height: 12),
              _RadioOption(
                value: 'target_sl_percent',
                groupValue: _exitType,
                title: 'Target/SL Percentage',
                subtitle: 'Exit based on percentage gain/loss',
                icon: Icons.percent,
                onChanged: (value) => setState(() => _exitType = value!),
              ),
              const SizedBox(height: 12),
              // _RadioOption(
              //   value: 'sma_based',
              //   groupValue: _exitType,
              //   title: 'SMA Based',
              //   subtitle: 'Exit when close price crosses SMA',
              //   icon: Icons.timeline,
              //   onChanged: (value) => setState(() => _exitType = value!),
              // ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_exitType == 'target_sl_points') _buildTargetSLPointsConfig(isDark),
        if (_exitType == 'target_sl_percent')
          _buildTargetSLPercentConfig(isDark),
        // if (_exitType == 'sma_based') _buildSMABasedConfig(isDark),
      ],
    );
  }

  Widget _buildTargetSLPointsConfig(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Configuration',
      child: Column(
        children: [
          TextFormField(
            controller: _targetPointsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Target Points',
              prefixIcon: const Icon(Icons.trending_up),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (_exitType == 'target_sl_points' &&
                  (value == null || value.isEmpty)) {
                return 'Please enter target points';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _slPointsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Stop Loss Points',
              prefixIcon: const Icon(Icons.trending_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (_exitType == 'target_sl_points' &&
                  (value == null || value.isEmpty)) {
                return 'Please enter stop loss points';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSLPercentConfig(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      title: 'Configuration',
      child: Column(
        children: [
          TextFormField(
            controller: _targetPercentController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Target Percentage',
              prefixIcon: const Icon(Icons.trending_up),
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (_exitType == 'target_sl_percent' &&
                  (value == null || value.isEmpty)) {
                return 'Please enter target percentage';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _slPercentController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Stop Loss Percentage',
              prefixIcon: const Icon(Icons.trending_down),
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (_exitType == 'target_sl_percent' &&
                  (value == null || value.isEmpty)) {
                return 'Please enter stop loss percentage';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _RadioOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : colorScheme.onSurface.withOpacity(0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onSelected;

  const _ChoiceChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onSelect;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
