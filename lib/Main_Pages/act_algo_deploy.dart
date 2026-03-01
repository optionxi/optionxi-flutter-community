import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:optionxi/Main_Pages/act_algo_result.dart';
import 'package:optionxi/Main_Pages/act_algo_result_history.dart';

class AlgoDesignerPage extends StatefulWidget {
  const AlgoDesignerPage({Key? key}) : super(key: key);

  @override
  State<AlgoDesignerPage> createState() => _AlgoDesignerPageState();
}

class _AlgoDesignerPageState extends State<AlgoDesignerPage> {
  final FirebaseDatabase db = FirebaseDatabase.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // State
  String selectedInstrument = 'NIFTY';
  String algoLogic = 'all';
  List<AlgoCondition> conditions = [];
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;
  bool isSubscribed = false;
  int savedAlgoCount = 0;
  String? currentAlgoId; // ID of the algo being designed/saved

  // API URL (Use 10.0.2.2 for Android Emulator, localhost for iOS/Web)
  final String apiUrl = 'http://localhost:8000/api/run-backtest';

  @override
  void initState() {
    super.initState();
    conditions.add(AlgoCondition());
    _checkSubscriptionAndLoad();
  }

  Future<void> _checkSubscriptionAndLoad() async {
    setState(() => isLoading = true);
    String uid = auth.currentUser!.uid;

    try {
      // 1. Check Subscription
      final subRef = db.ref().child('subscriptions/$uid/subscribed');
      final subSnapshot = await subRef.get();
      isSubscribed = subSnapshot.value == true;

      // 2. Check Existing Algos Count
      final algosRef = db.ref().child('algo/$uid');
      final algoSnapshot = await algosRef.get();
      savedAlgoCount = algoSnapshot.children.length;
    } catch (e) {
      _showSnackBar('Error loading profile: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleSaveAndBacktest() async {
    if (nameController.text.isEmpty) {
      _showSnackBar('Please name your strategy', isError: true);
      return;
    }

    // --- Subscription Logic ---
    if (!isSubscribed && savedAlgoCount >= 5 && currentAlgoId == null) {
      _showSubscriptionDialog();
      return;
    }
    // --------------------------

    setState(() => isLoading = true);
    String uid = auth.currentUser!.uid;

    try {
      // 1. Prepare Data
      final algoData = {
        'name': nameController.text,
        'instrument': selectedInstrument,
        'logic': algoLogic,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'updatedAt': ServerValue.timestamp,
      };

      // 2. Save to Firebase (Create new or Update existing)
      DatabaseReference ref;
      if (currentAlgoId == null) {
        ref = db.ref().child('algo/$uid').push();
        currentAlgoId = ref.key;
        savedAlgoCount++; // Increment local count
      } else {
        ref = db.ref().child('algo/$uid/$currentAlgoId');
      }
      await ref.update(algoData);

      // 3. Trigger Backtest on FastAPI
      String? token = await auth.currentUser?.getIdToken();

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'algoId': currentAlgoId,
          'name': nameController.text,
          'instrument': selectedInstrument,
          'logic': algoLogic,
          'conditions': conditions.map((c) => c.toJson()).toList(),
          'days_back': 30
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Backtest started! redirecting...');

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BacktestResultPage(
              algoId: currentAlgoId!,
              algoName: nameController.text,
            ),
          ),
        );
      } else {
        throw Exception('Server error: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Limit Reached"),
        content: const Text("Free tier allows only 1 strategy.\n\n"
            "Upgrade for ₹800/month to deploy unlimited strategies and access advanced backtesting."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar("Contact support for upgrade");
              // Add email/payment logic here
            },
            child: const Text("Upgrade Now"),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine Theme Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final primaryColor = Colors.indigoAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strategy Designer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Backtest History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BacktestHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Card(
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Strategy Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.show_chart),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSelectableChip(
                                    'NIFTY', selectedInstrument, (val) {
                                  setState(() => selectedInstrument = val);
                                }),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSelectableChip(
                                    'BANKNIFTY', selectedInstrument, (val) {
                                  setState(() => selectedInstrument = val);
                                }),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logic Toggle
                  Row(
                    children: [
                      const Text("Logic flow: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ToggleButtons(
                        isSelected: [algoLogic == 'all', algoLogic == 'any'],
                        onPressed: (index) {
                          setState(
                              () => algoLogic = index == 0 ? 'all' : 'any');
                        },
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("AND (All)")),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("OR (Any)")),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Conditions List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: conditions.length,
                    itemBuilder: (ctx, index) =>
                        _buildConditionCard(index, cardColor),
                  ),

                  // Add Condition Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => conditions.add(AlgoCondition())),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Add Condition"),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Run Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _handleSaveAndBacktest,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Run Backtest & Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectableChip(
      String label, String currentGroupValue, Function(String) onSelect) {
    final bool isSelected = label == currentGroupValue;
    return InkWell(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
              color: isSelected ? Colors.indigo : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.indigo : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionCard(int index, Color? cardColor) {
    final c = conditions[index];
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Condition ${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (conditions.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle,
                        color: Colors.redAccent, size: 20),
                    onPressed: () => setState(() => conditions.removeAt(index)),
                  )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: c.indicator1,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Indicator',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                    items: AlgoCondition.indicators
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setState(() => c.indicator1 = v!),
                  ),
                ),
                if (AlgoCondition.indicatorsWithPeriod
                    .contains(c.indicator1)) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildPeriodSelector(c.indicator1, c.period1,
                        (v) => setState(() => c.period1 = v)),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: c.operator,
                    decoration: const InputDecoration(
                        labelText: 'Op',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    items: AlgoCondition.operators
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => c.operator = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: c.indicator2,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Vs Indicator',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    items: AlgoCondition.indicators
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(e.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setState(() => c.indicator2 = v!),
                  ),
                ),
                if (AlgoCondition.indicatorsWithPeriod
                    .contains(c.indicator2)) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildPeriodSelector(c.indicator2, c.period2,
                        (v) => setState(() => c.period2 = v)),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(
      String indicator, int currentVal, Function(int) onChange) {
    // Specific standard periods based on technical analysis defaults
    List<int> periods = [5, 9, 10, 14, 20, 21, 50, 100, 200];

    return DropdownButtonFormField<int>(
      value: periods.contains(currentVal) ? currentVal : periods.first,
      decoration: const InputDecoration(
          labelText: 'Period',
          contentPadding: EdgeInsets.symmetric(horizontal: 8)),
      items: periods
          .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
          .toList(),
      onChanged: (v) => onChange(v!),
    );
  }
}

class AlgoCondition {
  String indicator1;
  String operator;
  String indicator2;
  int period1;
  int period2;

  AlgoCondition({
    this.indicator1 = 'close',
    this.operator = '>',
    this.indicator2 = 'ema',
    this.period1 = 14,
    this.period2 = 14,
  });

  // Removed Multiplier from logic as requested for simplicity
  Map<String, dynamic> toJson() => {
        'indicator1': indicator1,
        'operator': operator,
        'indicator2': indicator2,
        'period1': period1,
        'period2': period2,
      };

  static const List<String> indicators = [
    'close',
    'open',
    'high',
    'low',
    'volume',
    'sma',
    'ema',
    'rsi',
    'volume_prev',
    'close_prev'
  ];
  static const List<String> indicatorsWithPeriod = ['sma', 'ema', 'rsi'];
  static const List<String> operators = ['>', '<', '>=', '<=', '=='];
}
