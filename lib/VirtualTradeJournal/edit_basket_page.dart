import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';
import 'package:optionxi/VirtualTradeJournal/add_basket_page.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_holdings_journal.dart';

class EditBasketPage extends StatefulWidget {
  final BasketUserHolding basket;

  const EditBasketPage({
    Key? key,
    required this.basket,
  }) : super(key: key);

  @override
  _EditBasketPageState createState() => _EditBasketPageState();
}

class _EditBasketPageState extends State<EditBasketPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _submitController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();

  String? _selectedReason = 'Technical Breakout'; // Set default reason
  String _selectedTimeframe = 'Short Term';
  late DateTime _selectedEntryDate;
  bool _isSubmitting = false;
  // <<<--- ADDED: State for collapsible sections
  bool _isRiskManagementExpanded = false;
  bool _isWhyThisTradeExpanded = false;

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

    // Initialize the reason text field with the default value
    _customReasonController.text = 'Technical Breakout';

    _prefillFromHoldings(widget.basket);

    _buyPriceController.addListener(_updateTargetAndStopLoss);
  }

  void _prefillFromHoldings(BasketUserHolding holdings) {
    _buyPriceController.text = holdings.entryPrice.toStringAsFixed(2);
    _quantityController.text = holdings.quantity.toString();
    _targetController.text = holdings.targetPrice?.toStringAsFixed(2) ?? '';
    _stopLossController.text = holdings.stopLossPrice?.toStringAsFixed(2) ?? '';
    _selectedTimeframe = holdings.timeframe;
    _selectedEntryDate = holdings.entryDate;

    // <<<--- MODIFIED: Sync chip selection with the text field
    final allReasons = [..._positiveReasons, ..._negativeReasons]
        .map((r) => r['title'])
        .toList();
    if (holdings.reason != null) {
      if (allReasons.contains(holdings.reason)) {
        _selectedReason = holdings.reason;
      }
      _customReasonController.text = holdings.reason!;
    } else {
      // If no reason was set in holdings, keep the default
      _selectedReason = 'Technical Breakout';
      _customReasonController.text = 'Technical Breakout';
    }
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

  @override
  void dispose() {
    _animationController.dispose();
    _submitController.dispose();
    _buyPriceController.removeListener(_updateTargetAndStopLoss);
    _buyPriceController.dispose();
    _targetController.dispose();
    _stopLossController.dispose();
    _quantityController.dispose();
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEntryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedEntryDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedEntryDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
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
          databaseRef.child('virtualbasket_toedit').child(user.uid).push();

      // <<<--- MODIFIED: Add 'to_update' flag if editing
      final entryData = {
        'symbol': widget.basket.symbol,
        'segment': "EQ",
        'entry_price': double.tryParse(_buyPriceController.text) ?? 0.0,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'target_price': _targetController.text.isNotEmpty
            ? double.tryParse(_targetController.text)
            : null,
        'stop_loss_price': _stopLossController.text.isNotEmpty
            ? double.tryParse(_stopLossController.text)
            : null,
        'timeframe': _selectedTimeframe,
        'reason': _customReasonController
            .text, // <<<--- MODIFIED: Always take from controller
        'entry_date': _selectedEntryDate.toUtc().toIso8601String(),
        'isshort': widget.basket.isshort
      };

      await journalEntryRef.set(entryData);

      final successMessage =
          "${widget.basket.symbol} was successfully updated in your basket!";

      // GlobalSnackBarGet().showGetSuccessOnTop("Basket Updated", successMessage,
      //     backgroundColor: Colors.green.shade600);

      final int uniqueId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      NotificationService().showNotificationBasic(
        id: uniqueId,
        title: "Basket Updated",
        body: successMessage,
      );

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      GlobalSnackBarGet().showGetSuccessOnTop(
          "Failed", "Basket operation failed.",
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
                                  _buildRiskManagement(isDark), // MODIFIED
                                  const SizedBox(height: 24),
                                  _buildReasonSelector(isDark), // MODIFIED
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
    final title = "Edit Basket Entry";

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
            "Edit the details of the basket, including stock quantities, price limits, and reason.",
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
            ],
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildInputFormField(
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateTimePicker(
            label: 'Entry Date',
            dateTime: _selectedEntryDate,
            isDark: isDark,
            onTap: () => _selectDateTime(context),
          ),
          const SizedBox(height: 16),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _buildInputFormField(
          //         'Quantity',
          //         _quantityController,
          //         Icons.numbers_rounded,
          //         Colors.purple,
          //         isDark,
          //         validator: (value) {
          //           if (value == null || value.isEmpty) {
          //             return 'Quantity is required.';
          //           }
          //           if (int.tryParse(value) == null) {
          //             return 'Invalid number.';
          //           }
          //           return null;
          //         },
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeframe,
                  decoration: InputDecoration(
                    labelText: 'Timeframe',
                    prefixIcon:
                        Icon(Icons.schedule_rounded, color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[50],
                  ),
                  items: ['Intraday', 'Short Term', 'Long Term', 'Swing']
                      .map((timeframe) => DropdownMenuItem(
                            value: timeframe,
                            child: Text(timeframe),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedTimeframe = value!),
                ),
              ),
            ],
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
    final DateFormat displayFormat = DateFormat('dd-MM-yy hh:mm a z');

    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          // Add a controller to properly display the selected date
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
        prefixText: prefix.isEmpty ? null : prefix,
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

  // <<<--- MODIFIED: Refactored to be collapsible
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
                              // <<<--- MODIFIED: When user types, deselect any chip
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
        // <<<--- MODIFIED: Update text field when chip is tapped
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

  // <<<--- MODIFIED: Refactored to be collapsible
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

  Widget _buildSubmitButton(bool isDark) {
    final buttonText = "Update Basket";
    return GestureDetector(
      onTap: _isSubmitting ? null : _submitToJournal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: _isSubmitting
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.grey.shade700, Colors.grey.shade800]
                      : [Colors.grey.shade400, Colors.grey.shade500],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF3B82F6), // Blue
                    const Color(0xFF6366F1), // Indigo
                    const Color(0xFF8B5CF6), // Purple
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
                        buttonText,
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
    );
  }
}
