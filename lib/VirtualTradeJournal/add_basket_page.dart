import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/DataModels/dm_stock_model.dart';
import 'package:optionxi/Helpers/badge_service_obx.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';
import 'package:optionxi/VirtualTradeJournal/dialog_order_sucess.dart';

class AddToBasketPage extends StatefulWidget {
  final DataStockModel stock;

  const AddToBasketPage({Key? key, required this.stock}) : super(key: key);

  @override
  State<AddToBasketPage> createState() => _AddToBasketPageState();
}

class _AddToBasketPageState extends State<AddToBasketPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();

  late AnimationController _pageAnimController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String _selectedAction = 'BUY';
  String _selectedTimeframe = 'Short Term';
  late DateTime _selectedEntryDate;
  bool _isSubmitting = false;

  double? _targetPercent;
  double? _stopLossPercent;

  final List<String> _reasons = [
    'Technical Breakout',
    'Strong Fundamentals',
    'Volume Surge',
    'Support Level',
    'News Based',
    'FOMO Entry',
    'Social Media Hype',
  ];

  final List<String> _timeframes = [
    'Intraday',
    'Swing',
    'Short Term',
    'Long Term',
  ];

  Color get _buyColor => const Color(0xFF00C896);
  Color get _sellColor => const Color(0xFFFF4D6A);
  Color get _activeColor => _selectedAction == 'BUY' ? _buyColor : _sellColor;

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim =
        CurvedAnimation(parent: _pageAnimController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _pageAnimController, curve: Curves.easeOutCubic),
    );
    _pageAnimController.forward();

    _setDefaults();
    _targetController.addListener(_recalc);
    _stopLossController.addListener(_recalc);
  }

  void _setDefaults() {
    _quantityController.text = '1';
    _selectedEntryDate = DateTime.now();
    _customReasonController.text = 'Technical Breakout';
    _updateRiskLevels();
  }

  void _updateRiskLevels() {
    final ltp = widget.stock.close;
    if (ltp > 0) {
      final isBuy = _selectedAction == 'BUY';
      final target = (isBuy ? ltp * 1.05 : ltp * 0.95).clamp(0.0, 999999.0);
      final sl = (isBuy ? ltp * 0.98 : ltp * 1.02).clamp(0.0, 999999.0);
      _targetController.text = target.toStringAsFixed(2);
      _stopLossController.text = sl.toStringAsFixed(2);
      _recalc();
    }
  }

  void _recalc() {
    final entry = widget.stock.close;
    final target = double.tryParse(_targetController.text);
    final sl = double.tryParse(_stopLossController.text);
    setState(() {
      _targetPercent = (target != null && entry > 0)
          ? ((target - entry) / entry) * 100
          : null;
      _stopLossPercent =
          (sl != null && entry > 0) ? ((sl - entry) / entry) * 100 : null;
    });
  }

  void _toggleAction(String action) {
    if (_selectedAction == action) return;
    setState(() => _selectedAction = action);
    _updateRiskLevels();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _pageAnimController.dispose();
    _targetController.dispose();
    _stopLossController.dispose();
    _quantityController.dispose();
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0) {
      GlobalSnackBarGet().showGetSuccessOnTop(
        "Invalid Quantity",
        "Please enter at least 1.",
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final ref = FirebaseDatabase.instance
          .ref()
          .child('virtualbasket_toadd')
          .child(user.uid)
          .push();

      await ref.set({
        'symbol': widget.stock.symbol,
        'segment': 'EQ',
        'transaction_type': _selectedAction,
        'entry_price': widget.stock.close,
        'quantity': qty,
        'target_price': double.tryParse(_targetController.text),
        'stop_loss_price': double.tryParse(_stopLossController.text),
        'timeframe': _selectedTimeframe,
        'reason': _customReasonController.text,
        'entry_date': _selectedEntryDate.toUtc().toIso8601String(),
        'created_at': ServerValue.timestamp,
      });

      await BasketBadgeServiceObx.incrementBasketBadge();

      if (mounted) {
        NotificationService().showNotificationBasic(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: "Added to Basket",
          body: "${widget.stock.symbol} added as $_selectedAction position.",
        );
        showOrderPlacedDialog(context, false);
      }
    } catch (_) {
      GlobalSnackBarGet().showGetSuccessOnTop(
        "Error",
        "Could not save. Try again.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _displaySymbol => widget.stock.symbol
      .replaceAll('NSE:', '')
      .replaceAll('BSE:', '')
      .split('-')[0];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0C0E14) : const Color(0xFFF0F2F8),
      // Bottom bar is part of the Column, NOT a floatingActionButton,
      // so it never overlaps scrollable content and is always fully opaque.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false, // _BottomBar handles its own SafeArea
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── Sticky header ──────────────────────────────────────────
                _StockHeader(
                  displaySymbol: _displaySymbol,
                  stock: widget.stock,
                  isDark: isDark,
                  activeColor: _activeColor,
                  logoUrl: '${Constants.OptionXiS3Loc}$_displaySymbol.png',
                  onBack: () => Navigator.pop(context),
                ),

                // ── Scrollable body ────────────────────────────────────────
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      children: [
                        _ActionToggle(
                          selected: _selectedAction,
                          isDark: isDark,
                          buyColor: _buyColor,
                          sellColor: _sellColor,
                          onToggle: _toggleAction,
                        ),
                        const SizedBox(height: 26),
                        _SectionLabel(label: 'Quantity', isDark: isDark),
                        const SizedBox(height: 10),
                        _QuantityRow(
                          controller: _quantityController,
                          isDark: isDark,
                          activeColor: _activeColor,
                        ),
                        const SizedBox(height: 26),
                        _SectionLabel(
                          label: 'Risk Management',
                          isDark: isDark,
                          icon: Icons.security_rounded,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _RiskField(
                                label: 'Stop Loss',
                                controller: _stopLossController,
                                isDark: isDark,
                                percent: _stopLossPercent,
                                accentColor: const Color(0xFFFF4D6A),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _RiskField(
                                label: 'Target',
                                controller: _targetController,
                                isDark: isDark,
                                percent: _targetPercent,
                                accentColor: const Color(0xFF00C896),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _SectionLabel(
                          label: 'Timeframe',
                          isDark: isDark,
                          icon: Icons.schedule_rounded,
                        ),
                        const SizedBox(height: 10),
                        _TimeframeSelector(
                          selected: _selectedTimeframe,
                          options: _timeframes,
                          isDark: isDark,
                          activeColor: _activeColor,
                          onSelect: (v) =>
                              setState(() => _selectedTimeframe = v),
                        ),
                        const SizedBox(height: 26),
                        _SectionLabel(
                          label: 'Trade Reason',
                          isDark: isDark,
                          icon: Icons.psychology_rounded,
                        ),
                        const SizedBox(height: 10),
                        _ReasonSection(
                          controller: _customReasonController,
                          reasons: _reasons,
                          isDark: isDark,
                          activeColor: _activeColor,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Fully opaque bottom bar ────────────────────────────────
                _BottomBar(
                  isDark: isDark,
                  activeColor: _activeColor,
                  action: _selectedAction,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _StockHeader extends StatelessWidget {
  final String displaySymbol;
  final DataStockModel stock;
  final bool isDark;
  final Color activeColor;
  final String logoUrl;
  final VoidCallback onBack;

  const _StockHeader({
    required this.displaySymbol,
    required this.stock,
    required this.isDark,
    required this.activeColor,
    required this.logoUrl,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF12151C) : Colors.white;
    final divider = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textSub = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: logoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Image.asset(
                        'assets/images/stockdefault.png',
                        fit: BoxFit.cover),
                    errorWidget: (_, __, ___) => Image.asset(
                        'assets/images/stockdefault.png',
                        fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + sub
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displaySymbol,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stock.stckname,
                      style: TextStyle(fontSize: 11.5, color: textSub),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // LTP
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LTP',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: textSub,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '₹${stock.close.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: activeColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: divider),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final IconData? icon;

  const _SectionLabel({required this.label, required this.isDark, this.icon});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
        ],
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionToggle extends StatelessWidget {
  final String selected;
  final bool isDark;
  final Color buyColor, sellColor;
  final void Function(String) onToggle;

  const _ActionToggle({
    required this.selected,
    required this.isDark,
    required this.buyColor,
    required this.sellColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D26) : const Color(0xFFECEEF3),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab('BUY', buyColor),
          const SizedBox(width: 4),
          _tab('SELL', sellColor),
        ],
      ),
    );
  }

  Widget _tab(String label, Color color) {
    final isActive = selected == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => onToggle(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == 'BUY'
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 17,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white30 : Colors.black26),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  letterSpacing: 0.6,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.white30 : Colors.black26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuantityRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color activeColor;

  const _QuantityRow({
    required this.controller,
    required this.isDark,
    required this.activeColor,
  });

  void _change(int delta) {
    final current = int.tryParse(controller.text) ?? 0;
    final next = (current + delta).clamp(1, 10000);
    controller.text = next.toString();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0D1117);

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _QtyBtn(
            icon: Icons.remove_rounded,
            isDark: isDark,
            isLeft: true,
            bgColor: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
            iconColor: isDark ? Colors.white54 : Colors.black45,
            onTap: () => _change(-1),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '1',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((old, newVal) {
                  if (newVal.text.isEmpty) return newVal;
                  final v = int.tryParse(newVal.text) ?? 0;
                  return v > 10000 ? old : newVal;
                }),
              ],
            ),
          ),
          _QtyBtn(
            icon: Icons.add_rounded,
            isDark: isDark,
            isLeft: false,
            bgColor: activeColor.withOpacity(0.12),
            iconColor: activeColor,
            onTap: () => _change(1),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isLeft;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QtyBtn({
    required this.icon,
    required this.isDark,
    required this.isLeft,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(17) : Radius.zero,
            right: !isLeft ? const Radius.circular(17) : Radius.zero,
          ),
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formatter: caps decimal input at maxValue (999999) and blocks non-numeric
class _DecimalCapFormatter extends TextInputFormatter {
  final double maxValue;
  const _DecimalCapFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    // Allow incomplete decimals like "123." while typing
    if (newValue.text.endsWith('.')) return newValue;
    final v = double.tryParse(newValue.text);
    if (v == null) return oldValue;
    if (v > maxValue) return oldValue;
    return newValue;
  }
}

class _RiskField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final double? percent;
  final Color accentColor;

  const _RiskField({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.percent,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final textMuted =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.3,
                ),
              ),
              if (percent != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${percent! > 0 ? '+' : ''}${percent!.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    // Allow digits and a single decimal point
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    _DecimalCapFormatter(999999),
                  ],
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TimeframeSelector extends StatelessWidget {
  final String selected;
  final List<String> options;
  final bool isDark;
  final Color activeColor;
  final void Function(String) onSelect;

  const _TimeframeSelector({
    required this.selected,
    required this.options,
    required this.isDark,
    required this.activeColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final opt = options[i];
        final isActive = opt == selected;
        final isLast = i == options.length - 1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              onSelect(opt);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withOpacity(0.13)
                    : (isDark ? const Color(0xFF1A1D26) : Colors.white),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isActive
                      ? activeColor.withOpacity(0.45)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive
                      ? activeColor
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ReasonSection extends StatefulWidget {
  final TextEditingController controller;
  final List<String> reasons;
  final bool isDark;
  final Color activeColor;

  const _ReasonSection({
    required this.controller,
    required this.reasons,
    required this.isDark,
    required this.activeColor,
  });

  @override
  State<_ReasonSection> createState() => _ReasonSectionState();
}

class _ReasonSectionState extends State<_ReasonSection> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1A1D26) : Colors.white;
    final textPrimary = widget.isDark ? Colors.white : const Color(0xFF0D1117);
    final textMuted =
        widget.isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.07),
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Describe your trade thesis...',
              hintStyle: TextStyle(color: textMuted, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.reasons.map((r) {
            final isActive = widget.controller.text.trim() == r;
            return GestureDetector(
              onTap: () {
                widget.controller.text = r;
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? widget.activeColor.withOpacity(0.13)
                      : (widget.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isActive
                        ? widget.activeColor.withOpacity(0.45)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  r,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? widget.activeColor : textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar — placed inside Column so it NEVER overlaps scroll content
// and is always 100% opaque (no floating, no transparency issues)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isDark;
  final Color activeColor;
  final String action;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.isDark,
    required this.activeColor,
    required this.action,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // Match the header background so it feels like a bottom sheet
    final barBg = isDark ? const Color(0xFF12151C) : Colors.white;
    final divider = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(top: BorderSide(color: divider, width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Disclaimer
            Row(
              children: [
                Icon(Icons.school_outlined,
                    size: 13, color: Colors.blue.shade400),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Educational use only — no real money involved.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // CTA button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: activeColor.withOpacity(0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            action == 'BUY'
                                ? Icons.add_shopping_cart_rounded
                                : Icons.sell_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Add $action to Basket',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
