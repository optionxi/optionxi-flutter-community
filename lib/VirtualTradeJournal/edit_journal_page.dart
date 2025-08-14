import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';
import 'package:optionxi/VirtualTradeJournal/add_basket_page.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_tradehistory.dart';

class EditJournalPage extends StatefulWidget {
  final JournalTradeHistory journal;

  const EditJournalPage({
    Key? key,
    required this.journal,
  }) : super(key: key);

  @override
  _EditJournalPageState createState() => _EditJournalPageState();
}

class _EditJournalPageState extends State<EditJournalPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _submitController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();

  // Existing Controllers
  final TextEditingController _buyPriceController =
      TextEditingController(); // Entry Price
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();

  // Controllers for other fields
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _segmentController = TextEditingController();
  final TextEditingController _priceController =
      TextEditingController(); // This is now Exit Price
  final TextEditingController _chargesController = TextEditingController();
  final TextEditingController _profitLossController = TextEditingController();

  String _selectedAction = 'LONG';
  String? _selectedReason = 'Technical Breakout'; // Set default reason
  String _selectedTimeframe = 'Short Term';
  late DateTime _selectedEntryDate;
  late DateTime _selectedExitTime; // Renamed from _selectedExitTime
  bool _isDeleting = false;

  bool _isSubmitting = false;
  bool _isRiskManagementExpanded = false;
  bool _isWhyThisTradeExpanded = false;
  bool _isAdditionalDetailsExpanded = false;

  final List<Map<String, dynamic>> _positiveReasons = [
    {
      'title': 'Technical Breakout',
      'icon': Icons.trending_up,
      'color': Colors.green
    },
    {
      'title': 'Strong Fundamentals',
      'icon': Icons.analytics,
      'color': Colors.blue
    },
    {'title': 'Volume Surge', 'icon': Icons.bar_chart, 'color': Colors.orange},
    {'title': 'Support Level', 'icon': Icons.support, 'color': Colors.teal},
  ];

  final List<Map<String, dynamic>> _negativeReasons = [
    {
      'title': 'Social Media Hype',
      'icon': Icons.chat_bubble,
      'color': Colors.red
    },
    {
      'title': 'News Based',
      'icon': Icons.newspaper,
      'color': Colors.deepOrange
    },
    {
      'title': 'Guru Recommendation',
      'icon': Icons.person,
      'color': Colors.pink
    },
    {'title': 'FOMO Entry', 'icon': Icons.psychology, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _submitController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    _prefillFromHoldings(widget.journal);

    // Add listeners
    _buyPriceController.addListener(_updateTargetAndStopLoss);
    _buyPriceController.addListener(_calculateAndUpdateProfitLoss);
    _priceController.addListener(_calculateAndUpdateProfitLoss);
    _quantityController.addListener(_calculateAndUpdateProfitLoss);
    _chargesController.addListener(_calculateAndUpdateProfitLoss);
  }

  void _prefillFromHoldings(JournalTradeHistory holdings) {
    // Core fields
    _buyPriceController.text = holdings.entryPrice.toStringAsFixed(2);
    _quantityController.text = holdings.quantity.toString();
    _targetController.text = holdings.targetPrice?.toStringAsFixed(2) ?? '';
    _stopLossController.text = holdings.stopLossPrice?.toStringAsFixed(2) ?? '';
    _selectedAction =
        holdings.isShortSell ? "SHORT" : "LONG"; // Prefills LONG/SHORT
    _selectedTimeframe = holdings.timeframe;
    _selectedEntryDate = holdings.entryDate;
    _selectedExitTime = holdings.exitDate; // This is now Exit Time

    // Other details
    _symbolController.text = holdings.symbol;
    _segmentController.text = holdings.segment;
    _priceController.text = holdings.exitPrice.toStringAsFixed(2); // Exit Price
    _chargesController.text = holdings.charges.toStringAsFixed(2);

    final allReasons = [..._positiveReasons, ..._negativeReasons]
        .map((r) => r['title'])
        .toList();
    if (holdings.reason != null && holdings.reason!.isNotEmpty) {
      if (allReasons.contains(holdings.reason)) {
        _selectedReason = holdings.reason;
      } else {
        _selectedReason = null; // It's a custom reason
      }
      _customReasonController.text = holdings.reason!;
    } else {
      _selectedReason = 'Technical Breakout';
      _customReasonController.text = 'Technical Breakout';
    }

    // Initial calculation after prefilling data
    _calculateAndUpdateProfitLoss();
  }

  void _updateTargetAndStopLoss() {
    final double? entryPrice = double.tryParse(_buyPriceController.text);
    if (entryPrice != null && entryPrice > 0) {
      final double targetPrice = entryPrice * 1.08;
      final double stopLossPrice = entryPrice * 0.90;

      _targetController.text = targetPrice.toStringAsFixed(2);
      _stopLossController.text = stopLossPrice.toStringAsFixed(2);
    }
  }

  void _calculateAndUpdateProfitLoss() {
    final double entryPrice = double.tryParse(_buyPriceController.text) ?? 0.0;
    final double exitPrice = double.tryParse(_priceController.text) ?? 0.0;
    final int quantity = int.tryParse(_quantityController.text) ?? 0;
    final double charges = double.tryParse(_chargesController.text) ?? 0.0;

    double pnl = 0.0;

    if (quantity > 0 && entryPrice > 0) {
      if (_selectedAction == 'LONG') {
        pnl = (exitPrice - entryPrice) * quantity;
      } else {
        // SHORT
        pnl = (entryPrice - exitPrice) * quantity;
      }
    }

    final double netPnl = pnl - charges;

    if (mounted) {
      setState(() {
        _profitLossController.text = netPnl.toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _submitController.dispose();

    // Remove all listeners
    _buyPriceController.removeListener(_updateTargetAndStopLoss);
    _buyPriceController.removeListener(_calculateAndUpdateProfitLoss);
    _priceController.removeListener(_calculateAndUpdateProfitLoss);
    _quantityController.removeListener(_calculateAndUpdateProfitLoss);
    _chargesController.removeListener(_calculateAndUpdateProfitLoss);

    // Dispose all controllers
    _buyPriceController.dispose();
    _targetController.dispose();
    _stopLossController.dispose();
    _quantityController.dispose();
    _customReasonController.dispose();
    _symbolController.dispose();
    _segmentController.dispose();
    _priceController.dispose();
    _chargesController.dispose();
    _profitLossController.dispose();

    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, DateTime initialDate,
      Function(DateTime) onDateTimeChanged) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        setState(() {
          onDateTimeChanged(DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
        });
      }
    }
  }

  void _deleteJournal() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to delete a journal entry.');
      }

      // Add your delete logic here - adjust the Firebase path as needed
      final databaseRef = FirebaseDatabase.instance.ref();
      await databaseRef
          .child('virtualjournal_todelete')
          .child(user.uid)
          .child(widget.journal.orderId.toString())
          .set({"todelete": true});

      GlobalSnackBarGet().showGetSuccessOnTop("Journal Deleted",
          "${_symbolController.text} was successfully deleted from your journal!",
          backgroundColor: Colors.red.shade600);

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      GlobalSnackBarGet().showGetSuccessOnTop(
          "Failed", "Failed to delete journal entry: $e",
          backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _submitToJournal() async {
    if (!_formKey.currentState!.validate()) {
      GlobalSnackBarGet().showGetSuccessOnTop(
          "Missing Values", "Please fill all the required fields.",
          backgroundColor: Colors.orangeAccent);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    _submitController.forward();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to create a journal entry.');
      }

      final databaseRef = FirebaseDatabase.instance.ref();
      final journalEntryRef =
          databaseRef.child('virtualjournal_toedit').child(user.uid).push();

      final entryData = {
        // Core trade details
        'symbol': _symbolController.text,
        'segment': _segmentController.text,
        'transaction_type': _selectedAction,
        'entry_price': double.tryParse(_buyPriceController.text) ?? 0.0,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'entry_date': _selectedEntryDate.toUtc().toIso8601String(),
        'exit_price': double.tryParse(_priceController.text) ?? 0.0,
        'exit_time': _selectedExitTime.toUtc().toIso8601String(),

        // Risk management
        'target_price': _targetController.text.isNotEmpty
            ? double.tryParse(_targetController.text)
            : null,
        'stop_loss_price': _stopLossController.text.isNotEmpty
            ? double.tryParse(_stopLossController.text)
            : null,

        // Trade rationale
        'timeframe': _selectedTimeframe,
        'reason': _customReasonController.text,

        // Additional trade data from TradeHistoryJournal
        'charges': double.tryParse(_chargesController.text) ?? 0.0,
        'profit_loss': double.tryParse(_profitLossController.text) ?? 0.0,

        // Metadata
        'suid': widget.journal.suid,
        'order_id': widget.journal.orderId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await journalEntryRef.set(entryData);

      // final successMessage =
      //     "${_symbolController.text} was successfully updated in your journal!";

      // GlobalSnackBarGet().showGetSuccessOnTop("Journal Updated", successMessage,
      //     backgroundColor: Colors.green.shade600);

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      GlobalSnackBarGet().showGetSuccessOnTop(
          "Failed", "Trade journal operation failed: $e",
          backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _submitController.reverse();
      }
    }
  }

  Widget buildColorfulActionButton(
    BuildContext context,
    bool isDark,
    String label,
    IconData icon,
    VoidCallback onPressed,
    bool isChartButton,
  ) {
    final primaryColor = isChartButton ? Colors.blue : Colors.deepPurple;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Form(
                      key: _formKey,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _buildPriceInputs(isDark),
                                  const SizedBox(height: 24),
                                  _buildRiskManagement(isDark),
                                  const SizedBox(height: 24),
                                  _buildReasonSelector(isDark),
                                  const SizedBox(height: 24),
                                  _buildAdditionalDetails(isDark),
                                  const SizedBox(height: 32),
                                  VirtualDisclaimerNotice(),
                                  const SizedBox(height: 32),
                                  _buildSubmitButton(isDark),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final fontSize = isTablet ? 32.0 : 28.0;
    final title = "Edit Journal Entry";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 20,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Edit the details of the journal, including stock quantities, price limits, and reason.",
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
              fontSize: isTablet ? 16.0 : 14.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToggle(bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      return ToggleButtons(
        isSelected: [_selectedAction == 'LONG', _selectedAction == 'SHORT'],
        onPressed: (int index) {
          setState(() {
            _selectedAction = index == 0 ? 'LONG' : 'SHORT';
          });
          _calculateAndUpdateProfitLoss(); // Recalculate P/L on action change
        },
        constraints: BoxConstraints.expand(
            width: (constraints.maxWidth / 2) - 4, height: 50),
        borderRadius: BorderRadius.circular(16),
        selectedBorderColor:
            _selectedAction == 'LONG' ? Colors.green : Colors.red,
        selectedColor: Colors.white,
        fillColor: _selectedAction == 'LONG'
            ? Colors.green.shade600
            : Colors.red.shade600,
        color: isDark ? Colors.white70 : Colors.black87,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up_rounded),
              SizedBox(width: 8),
              Text('LONG', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_down_rounded),
              SizedBox(width: 8),
              Text('SHORT', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildPriceInputs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1F1F1F),
                  const Color(0xFF2A2A2A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFFAFBFC),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Trade Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _symbolController,
            enabled: false, // Make it non-editable
            decoration: InputDecoration(
              labelText: 'Symbol',
              prefixIcon:
                  Icon(Icons.bar_chart_rounded, color: Colors.deepPurple),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  isDark ? Colors.white.withOpacity(0.03) : Colors.grey[100],
              labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputFormField(
                  'Quantity',
                  _quantityController,
                  Icons.numbers_rounded,
                  Colors.purple,
                  isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Quantity is required.';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Invalid number.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _segmentController,
                  enabled: false, // Make it non-editable
                  decoration: InputDecoration(
                    labelText: 'Segment',
                    prefixIcon:
                        Icon(Icons.category_rounded, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionToggle(isDark),
          const SizedBox(height: 20),
          _buildInputFormField(
            'Entry Price',
            _buyPriceController,
            Icons.input_rounded,
            Colors.blue,
            isDark,
            prefix: '₹',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Entry price is required.';
              }
              if (double.tryParse(value) == null) {
                return 'Invalid number.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildDateTimePicker(
            label: 'Entry Date',
            dateTime: _selectedEntryDate,
            isDark: isDark,
            onTap: () =>
                _selectDateTime(context, _selectedEntryDate, (newDate) {
              _selectedEntryDate = newDate;
            }),
          ),
          const SizedBox(height: 16),
          _buildInputFormField(
            'Exit Price',
            _priceController,
            Icons.output_rounded,
            Colors.red,
            isDark,
            prefix: '₹',
          ),
          const SizedBox(height: 16),
          _buildDateTimePicker(
            label: 'Exit Time',
            dateTime: _selectedExitTime,
            isDark: isDark,
            onTap: () => _selectDateTime(context, _selectedExitTime, (newDate) {
              _selectedExitTime = newDate;
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTimeframe,
            decoration: InputDecoration(
              labelText: 'Timeframe',
              prefixIcon: Icon(Icons.schedule_rounded, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            ),
            items: ['Intraday', 'Short Term', 'Long Term', 'Swing']
                .map((timeframe) => DropdownMenuItem(
                      value: timeframe,
                      child: Text(timeframe),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedTimeframe = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime dateTime,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final DateFormat displayFormat = DateFormat('dd-MM-yy hh:mm a');

    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          controller:
              TextEditingController(text: displayFormat.format(dateTime)),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
            prefixIcon: Icon(Icons.calendar_today_rounded, color: Colors.cyan),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor:
                isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInputFormField(String label, TextEditingController controller,
      IconData icon, Color color, bool isDark,
      {String prefix = '', String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        prefixText: prefix.isEmpty ? null : '$prefix ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[600],
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      validator: validator,
    );
  }

  Widget _buildReasonSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1F1F1F),
                  const Color(0xFF2A2A2A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFFAFBFC),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isWhyThisTradeExpanded = !_isWhyThisTradeExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology_rounded,
                      color: Colors.indigo,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why this trade?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                AnimatedRotation(
                  turns: _isWhyThisTradeExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 28,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isWhyThisTradeExpanded ? null : 0,
            child: AnimatedOpacity(
              opacity: _isWhyThisTradeExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isWhyThisTradeExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Reasons',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _positiveReasons.map((reason) {
                              final isSelected =
                                  _selectedReason == reason['title'];
                              return _buildReasonChip(
                                  reason, isSelected, isDark);
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Be Careful',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _negativeReasons.map((reason) {
                              final isSelected =
                                  _selectedReason == reason['title'];
                              return _buildReasonChip(
                                  reason, isSelected, isDark);
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _customReasonController,
                            decoration: InputDecoration(
                              labelText: 'Custom Reason',
                              prefixIcon: Icon(Icons.edit_note_rounded,
                                  color: Colors.teal),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.teal,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (_selectedReason != null) {
                                setState(() {
                                  _selectedReason = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip(
      Map<String, dynamic> reason, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedReason = null;
            _customReasonController.clear();
          } else {
            _selectedReason = reason['title'];
            _customReasonController.text = reason['title'];
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    reason['color'].withOpacity(0.8),
                    reason['color'].withOpacity(0.6),
                  ],
                )
              : null,
          color: !isSelected
              ? (isDark
                  ? Colors.white.withOpacity(0.05)
                  : reason['color'].withOpacity(0.1))
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: reason['color'].withOpacity(isSelected ? 0.8 : 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: reason['color'].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              reason['icon'],
              size: 18,
              color: isSelected ? Colors.white : reason['color'],
            ),
            const SizedBox(width: 8),
            Text(
              reason['title'],
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : reason['color']),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskManagement(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1F1F1F),
                  const Color(0xFF2A2A2A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFFAFBFC),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isRiskManagementExpanded = !_isRiskManagementExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Risk Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                AnimatedRotation(
                  turns: _isRiskManagementExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 28,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isRiskManagementExpanded ? null : 0,
            child: AnimatedOpacity(
              opacity: _isRiskManagementExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isRiskManagementExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInputFormField(
                              'Stop Loss',
                              _stopLossController,
                              Icons.trending_down_rounded,
                              Colors.red,
                              isDark,
                              prefix: '₹',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Stop loss is required.';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputFormField(
                              'Target',
                              _targetController,
                              Icons.flag_rounded,
                              Colors.green,
                              isDark,
                              prefix: '₹',
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    double.tryParse(value) == null) {
                                  return 'Invalid number.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails(bool isDark) {
    final double pnlValue = double.tryParse(_profitLossController.text) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1F1F1F), const Color(0xFF2A2A2A)]
              : [Colors.white, const Color(0xFFFAFBFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isAdditionalDetailsExpanded = !_isAdditionalDetailsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.blueGrey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                AnimatedRotation(
                  turns: _isAdditionalDetailsExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 28,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isAdditionalDetailsExpanded ? null : 0,
            child: AnimatedOpacity(
              opacity: _isAdditionalDetailsExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isAdditionalDetailsExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Column(
                        children: [
                          _buildInputFormField(
                            'Charges',
                            _chargesController,
                            Icons.receipt_long_rounded,
                            Colors.pink,
                            isDark,
                            prefix: '₹',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _profitLossController,
                            enabled: false, // Make it non-editable
                            decoration: InputDecoration(
                              labelText: 'Net Profit/Loss',
                              prefixIcon: Icon(
                                pnlValue >= 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color:
                                    pnlValue >= 0 ? Colors.green : Colors.red,
                              ),
                              prefixText: '₹ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.03)
                                  : Colors.grey[100],
                              labelStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              color: pnlValue >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Row(
      children: [
        // Delete Button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _isDeleting || _isSubmitting ? null : _deleteJournal,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: _isDeleting
                    ? LinearGradient(
                        colors: isDark
                            ? [Colors.grey.shade700, Colors.grey.shade800]
                            : [Colors.grey.shade400, Colors.grey.shade500],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.red.shade600,
                          Colors.red.shade700,
                        ],
                      ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isDeleting
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isDeleting
                      ? const SizedBox(
                          key: ValueKey('deleting'),
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          key: ValueKey('delete-content'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Delete",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Update Button
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: _isSubmitting || _isDeleting ? null : _submitToJournal,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: _isSubmitting
                    ? LinearGradient(
                        colors: isDark
                            ? [Colors.grey.shade700, Colors.grey.shade800]
                            : [Colors.grey.shade400, Colors.grey.shade500],
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6),
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                        ],
                      ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isSubmitting
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isSubmitting
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          key: ValueKey('content'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Update Journal",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
