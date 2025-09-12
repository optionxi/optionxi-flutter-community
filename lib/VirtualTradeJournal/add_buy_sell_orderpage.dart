import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:optionxi/Components/custom_slidetobuy.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/Helpers/badge_service_obx.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';
import 'package:optionxi/Main_Pages/act_atlas_page.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';
import 'package:optionxi/browser_lite.dart';

class AddBuySellOrderPage extends StatefulWidget {
  final DataStockModel stock;
  final String whichbroker;
  final String buyorsell;
  const AddBuySellOrderPage({
    Key? key,
    required this.stock,
    required this.whichbroker,
    required this.buyorsell,
  }) : super(key: key);

  @override
  _AddBuySellOrderPageState createState() => _AddBuySellOrderPageState();
}

class _AddBuySellOrderPageState extends State<AddBuySellOrderPage>
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

  String _selectedAction = 'BUY';
  bool _isExpanded = false;
  // <<<--- ADDED: State for collapsible sections
  bool _isRiskManagementExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedAction = widget.buyorsell;
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

    _setInitialDefaults();

    _buyPriceController.addListener(_updateTargetAndStopLoss);
  }

  void _setInitialDefaults() {
    _buyPriceController.text = widget.stock.close.toStringAsFixed(2);
    _quantityController.text = '1'; // <<<--- MODIFIED: Set default quantity
    _updateTargetAndStopLoss();
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

  void _submitToJournal() async {
    if (!_formKey.currentState!.validate()) {
      GlobalSnackBarGet().showGetSuccessOnTop(
          "Missing Values", "Please fill all the required fields.",
          backgroundColor: Colors.orangeAccent);
      return;
    }

    _submitController.forward();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to create a journal entry.');
      }

      final databaseRef = FirebaseDatabase.instance.ref();
      final orderRef = databaseRef
          .child('order_to_execute')
          .child(widget.whichbroker)
          .child(user.uid)
          .push();

      // <<<--- MODIFIED: Add 'to_update' flag if editing
      final orderData = {
        'symbol': widget.stock.symbol,
        'segment': "EQ",
        'transaction_type': _selectedAction,
        'entry_price': double.tryParse(_buyPriceController.text) ?? 0.0,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'target_price': _targetController.text.isNotEmpty
            ? double.tryParse(_targetController.text)
            : null,
        'stop_loss_price': _stopLossController.text.isNotEmpty
            ? double.tryParse(_stopLossController.text)
            : null,
        'reason': _customReasonController
            .text, // <<<--- MODIFIED: Always take from controller
      };

      // await journalEntryRef.set(entryData);
      // await BasketBadgeServiceObx.incrementBasketBadge();

      final successMessage =
          "Order placed for ${widget.stock.symbol} via ${widget.whichbroker} broker";

      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Row(
        //       children: [
        //         Icon(icon, color: Colors.white, size: 20),
        //         const SizedBox(width: 8),
        //         Expanded(
        //           child: Text(
        //             successMessage,
        //             style: const TextStyle(
        //               color: Colors.white,
        //               fontWeight: FontWeight.w500,
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //     backgroundColor: backgroundColor,
        //     duration: Duration(milliseconds: 1500),
        //     behavior: SnackBarBehavior.floating,
        //     margin: EdgeInsets.only(bottom: 70), // Add bottom margin
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //   ),
        // );

        final int uniqueId =
            DateTime.now().millisecondsSinceEpoch.remainder(100000);

        NotificationService().showNotificationBasic(
          id: uniqueId,
          title: "${widget.whichbroker}: Order Placed",
          body: successMessage,
        );
      }
      // await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      GlobalSnackBarGet().showGetSuccessOnTop(
          "Failed", "Trade basket operation failed.",
          backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        _submitController.reverse();
      }
    }
  }

  void _navigateToChart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => BrowserLite_V(
              "https://in.tradingview.com/chart/?symbol=NSE%3A" +
                  widget.stock.symbol.toString().split("-")[0].split(":")[1])),
    );
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
                                  _buildStockInfoCardWithActions(isDark),
                                  const SizedBox(height: 24),
                                  _buildPriceInputs(isDark),
                                  const SizedBox(height: 24),
                                  _buildRiskManagement(isDark), // MODIFIED
                                  const SizedBox(height: 32),
                                  VirtualDisclaimerNotice(),
                                  const SizedBox(height: 32),
                                  SlidetoBuyorSell(
                                    theme: Theme.of(context),
                                    onCompleted: _submitToJournal,
                                    orderType: _selectedAction,
                                  ),
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

  Widget _buildStockInfoCardWithActions(bool isDark) {
    final double _percentChange = widget.stock.pcnt;
    final double _currentPrice = widget.stock.close;
    final double _open = widget.stock.open;
    final double _high = widget.stock.high;
    final double _low = widget.stock.low;
    final double _prevClose = widget.stock.pclose;

    final Color gainColor =
        isDark ? Colors.green.shade400 : Colors.green.shade700;
    final Color lossColor = isDark ? Colors.red.shade400 : Colors.red.shade700;
    final Color changeColor = _percentChange >= 0 ? gainColor : lossColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            height: 52,
                            width: 52,
                            imageUrl: Constants.OptionXiS3Loc +
                                widget.stock.symbol
                                    .split(":")[1]
                                    .split("-")[0]
                                    .toString() +
                                ".png",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Image.asset(
                              'assets/images/stockdefault.png',
                              fit: BoxFit.cover,
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/stockdefault.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // widget.stock.stckname,
                              widget.stock.symbol.split(":")[1].split("-")[0],

                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                // widget.stock.symbol.split(":")[1].split("-")[0],
                                widget.stock.stckname,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: changeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: changeColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _percentChange >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: changeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_percentChange.abs().toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 13,
                                color: changeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    // crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        '₹${_currentPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded
                            ? 'Tap to hide details'
                            : 'Tap to view details',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isExpanded ? null : 0,
            child: AnimatedOpacity(
              opacity: _isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _isExpanded
                  ? Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          height: 1,
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE5E5E5),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildOhlcItem('Open',
                                          _open.toStringAsFixed(2), isDark)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildOhlcItem('High',
                                          _high.toStringAsFixed(2), isDark)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildOhlcItem('Low',
                                          _low.toStringAsFixed(2), isDark)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildOhlcItem(
                                          'Prev. Close',
                                          _prevClose.toStringAsFixed(2),
                                          isDark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: buildColorfulActionButton(
                                  context,
                                  isDark,
                                  'Chart',
                                  Icons.trending_up_rounded,
                                  () => _navigateToChart(context),
                                  true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: buildColorfulActionButton(
                                  context,
                                  isDark,
                                  'Alerts',
                                  Icons.analytics_outlined,
                                  () {
                                    if (widget.stock.sec == "FNO") {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AtlasOutputPage()));
                                    } else {
                                      Get.toNamed(
                                          '/alerts/${widget.stock.symbol.split(":")[1].split("-")[0]}');
                                    }
                                  },
                                  false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOhlcItem(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final fontSize = isTablet ? 32.0 : 28.0;
    final title = "Place Order";

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
            "Place Real Orders via ${widget.whichbroker} API. Read the terms and conditions properly ",
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
        isSelected: [_selectedAction == 'BUY', _selectedAction == 'SELL'],
        onPressed: (int index) {
          setState(() {
            _selectedAction = index == 0 ? 'BUY' : 'SELL';
          });
        },
        constraints: BoxConstraints.expand(
            width: (constraints.maxWidth / 2) - 4, height: 50),
        borderRadius: BorderRadius.circular(16),
        selectedBorderColor:
            _selectedAction == 'BUY' ? Colors.green : Colors.red,
        selectedColor: Colors.white,
        fillColor: _selectedAction == 'BUY'
            ? Colors.green.shade600
            : Colors.red.shade600,
        color: isDark ? Colors.white70 : Colors.black87,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up_rounded),
              SizedBox(width: 8),
              Text('BUY', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_down_rounded),
              SizedBox(width: 8),
              Text('SELL', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),
          _buildActionToggle(isDark),
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
          const SizedBox(height: 16),
        ],
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
}

class VirtualDisclaimerNotice extends StatelessWidget {
  const VirtualDisclaimerNotice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.indigo.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.privacy_tip_outlined,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disclaimer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By placing an order through this platform, you acknowledge that trades are executed via your broker’s API. We do not provide financial advice and are not responsible for trade outcomes, execution errors, delays, or losses. Please verify all details before confirming any order.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
