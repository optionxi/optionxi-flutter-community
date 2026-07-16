import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Helpers/global_snackbar_get.dart';
import 'package:optionxi/PushNotification/notifcation_service.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_tradehistory.dart';

/// Formats a P&L value with K / L / Cr shortening.
/// Examples: 1500 → 1.50K, 250000 → 2.50L, 12500000 → 1.25Cr
String formatShortPnL(double value) {
  final abs = value.abs();
  String formatted;
  if (abs >= 10000000) {
    formatted = '${(abs / 10000000).toStringAsFixed(2)}Cr';
  } else if (abs >= 100000) {
    formatted = '${(abs / 100000).toStringAsFixed(2)}L';
  } else if (abs >= 1000) {
    formatted = '${(abs / 1000).toStringAsFixed(2)}K';
  } else {
    formatted = abs.toStringAsFixed(2);
  }
  return value < 0 ? '-$formatted' : formatted;
}

class EditJournalPage extends StatefulWidget {
  final JournalTradeHistory journal;

  const EditJournalPage({
    Key? key,
    required this.journal,
  }) : super(key: key);

  @override
  State<EditJournalPage> createState() => _EditJournalPageState();
}

class _EditJournalPageState extends State<EditJournalPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _entryPriceController = TextEditingController();
  final TextEditingController _exitPriceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _stopLossController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _chargesController = TextEditingController();
  final TextEditingController _pnlController = TextEditingController();

  late AnimationController _pageAnimController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String _selectedAction = 'LONG';
  String _selectedTimeframe = 'Short Term';
  late DateTime _selectedEntryDate;
  late DateTime _selectedExitDate;
  bool _isSubmitting = false;
  bool _isDeleting = false;

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
    'Guru Recommendation',
  ];

  final List<String> _timeframes = [
    'Intraday',
    'Swing',
    'Short Term',
    'Long Term',
  ];

  // Color based on direction
  Color get _activeColor => _selectedAction == 'LONG'
      ? const Color(0xFF00C896)
      : const Color(0xFFFF4D6A);

  double get _pnlValue {
    final entry = double.tryParse(_entryPriceController.text) ?? 0.0;
    final exit = double.tryParse(_exitPriceController.text) ?? 0.0;
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final charges = double.tryParse(_chargesController.text) ?? 0.0;

    if (entry <= 0 || qty <= 0) return 0.0;

    double grossPnl =
        _selectedAction == 'LONG' ? (exit - entry) * qty : (entry - exit) * qty;

    return grossPnl - charges;
  }

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

    _prefillFromJournal();

    // Listeners for calculations
    _entryPriceController.addListener(_recalc);
    _exitPriceController.addListener(_recalc);
    _targetController.addListener(_recalc);
    _stopLossController.addListener(_recalc);
    _quantityController.addListener(_recalc);
    _chargesController.addListener(_updatePnL);
  }

  void _prefillFromJournal() {
    _entryPriceController.text = widget.journal.entryPrice.toStringAsFixed(2);
    _exitPriceController.text = widget.journal.exitPrice.toStringAsFixed(2);
    _quantityController.text = widget.journal.quantity.toString();
    _targetController.text =
        widget.journal.targetPrice?.toStringAsFixed(2) ?? '';
    _stopLossController.text =
        widget.journal.stopLossPrice?.toStringAsFixed(2) ?? '';
    _chargesController.text = widget.journal.charges.toStringAsFixed(2);
    _selectedAction = widget.journal.isShortSell ? "SHORT" : "LONG";
    _selectedTimeframe = widget.journal.timeframe;
    _selectedEntryDate = widget.journal.entryDate;
    _selectedExitDate = widget.journal.exitDate;
    _customReasonController.text =
        widget.journal.reason ?? 'Technical Breakout';

    _recalc();
    _updatePnL();
  }

  void _recalc() {
    final entry = double.tryParse(_entryPriceController.text) ?? 0.0;
    final target = double.tryParse(_targetController.text);
    final sl = double.tryParse(_stopLossController.text);

    setState(() {
      if (entry > 0) {
        _targetPercent =
            target != null ? ((target - entry) / entry) * 100 : null;
        _stopLossPercent = sl != null ? ((sl - entry) / entry) * 100 : null;
      } else {
        _targetPercent = null;
        _stopLossPercent = null;
      }
    });
  }

  void _updatePnL() {
    setState(() {
      _pnlController.text = _pnlValue.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _pageAnimController.dispose();
    _entryPriceController.dispose();
    _exitPriceController.dispose();
    _targetController.dispose();
    _stopLossController.dispose();
    _quantityController.dispose();
    _customReasonController.dispose();
    _chargesController.dispose();
    _pnlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final ref = FirebaseDatabase.instance
          .ref()
          .child('virtualjournal_toedit')
          .child(user.uid)
          .push();

      await ref.set({
        'symbol': widget.journal.symbol,
        'segment': widget.journal.segment,
        'transaction_type': _selectedAction,
        'entry_price': double.tryParse(_entryPriceController.text) ?? 0.0,
        'exit_price': double.tryParse(_exitPriceController.text) ?? 0.0,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
        'target_price': double.tryParse(_targetController.text),
        'stop_loss_price': double.tryParse(_stopLossController.text),
        'timeframe': _selectedTimeframe,
        'reason': _customReasonController.text,
        'entry_date': _selectedEntryDate.toUtc().toIso8601String(),
        'exit_time': _selectedExitDate.toUtc().toIso8601String(),
        'charges': double.tryParse(_chargesController.text) ?? 0.0,
        'profit_loss': _pnlValue,
        'suid': widget.journal.suid,
        'order_id': widget.journal.orderId,
        'updated_at': ServerValue.timestamp,
      });

      if (mounted) {
        NotificationService().showNotificationBasic(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: "Journal Updated",
          body: "${widget.journal.symbol} updated successfully.",
        );
        Navigator.pop(context);
      }
    } catch (_) {
      GlobalSnackBarGet().showGetSuccessOnTop(
        "Error",
        "Could not update. Try again.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      await FirebaseDatabase.instance
          .ref()
          .child('virtualjournal_todelete')
          .child(user.uid)
          .child(widget.journal.orderId.toString())
          .set({"todelete": true});

      if (mounted) Navigator.pop(context);
    } catch (_) {
      GlobalSnackBarGet().showGetSuccessOnTop(
        "Error",
        "Delete failed",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String get _displaySymbol => widget.journal.symbol
      .replaceAll('NSE:', '')
      .replaceAll('BSE:', '')
      .split('-')[0];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0C0E14) : const Color(0xFFF0F2F8),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── Sticky header ──────────────────────────────────────────
                _StockHeader(
                  displaySymbol: _displaySymbol,
                  journal: widget.journal,
                  isDark: isDark,
                  activeColor: _activeColor,
                  action: _selectedAction,
                  logoUrl: '${Constants.OptionXiS3Loc}$_displaySymbol.png',
                  onBack: () => Navigator.pop(context),
                  livePnl: _pnlValue,
                ),

                // ── Scrollable body ────────────────────────────────────────
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      children: [
                        const SizedBox(height: 4),
                        _SectionLabel(label: 'Quantity', isDark: isDark),
                        const SizedBox(height: 10),
                        _QuantityRow(
                          controller: _quantityController,
                          isDark: isDark,
                          activeColor: _activeColor,
                          onChanged: _updatePnL,
                        ),
                        const SizedBox(height: 26),
                        _SectionLabel(
                          label: 'Prices',
                          isDark: isDark,
                          icon: Icons.price_change_rounded,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _PriceField(
                                label: 'Entry',
                                controller: _entryPriceController,
                                isDark: isDark,
                                activeColor: _activeColor,
                                onChanged: _updatePnL,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _PriceField(
                                label: 'Exit',
                                controller: _exitPriceController,
                                isDark: isDark,
                                activeColor: _activeColor,
                                onChanged: _updatePnL,
                              ),
                            ),
                          ],
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
                          label: 'Charges & P&L',
                          isDark: isDark,
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ChargesField(
                                controller: _chargesController,
                                isDark: isDark,
                                onChanged: _updatePnL,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _PnLDisplay(
                                pnl: _pnlValue,
                                isDark: isDark,
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
                          label: 'Dates',
                          isDark: isDark,
                          icon: Icons.date_range_rounded,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _DatePickerField(
                                label: 'Entry',
                                date: _selectedEntryDate,
                                isDark: isDark,
                                onTap: () => _selectDateTime(true),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _DatePickerField(
                                label: 'Exit',
                                date: _selectedExitDate,
                                isDark: isDark,
                                onTap: () => _selectDateTime(false),
                              ),
                            ),
                          ],
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

                // ── Fully opaque bottom bar with delete ─────────────────────
                _BottomBar(
                  isDark: isDark,
                  activeColor: _activeColor,
                  isSubmitting: _isSubmitting,
                  isDeleting: _isDeleting,
                  onSubmit: _submit,
                  onDelete: _delete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateTime(bool isEntry) async {
    final initial = isEntry ? _selectedEntryDate : _selectedExitDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (time != null && mounted) {
        setState(() {
          final newDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          if (isEntry) {
            _selectedEntryDate = newDate;
          } else {
            _selectedExitDate = newDate;
          }
        });
      }
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _StockHeader extends StatelessWidget {
  final String displaySymbol;
  final JournalTradeHistory journal;
  final bool isDark;
  final Color activeColor;
  final String action;
  final String logoUrl;
  final VoidCallback onBack;
  final double livePnl;

  const _StockHeader({
    required this.displaySymbol,
    required this.journal,
    required this.isDark,
    required this.activeColor,
    required this.action,
    required this.logoUrl,
    required this.onBack,
    required this.livePnl,
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

              // Name + direction badge
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            action == 'LONG'
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 12,
                            color: activeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            action,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: activeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // P&L Badge — uses formatShortPnL for compact display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'P&L',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: textSub,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '₹${formatShortPnL(livePnl)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: livePnl >= 0
                          ? const Color(0xFF00C896)
                          : const Color(0xFFFF4D6A),
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

class _QuantityRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color activeColor;
  final VoidCallback? onChanged;

  const _QuantityRow({
    required this.controller,
    required this.isDark,
    required this.activeColor,
    this.onChanged,
  });

  void _change(int delta) {
    final current = int.tryParse(controller.text) ?? 0;
    final next = (current + delta).clamp(1, 10000);
    controller.text = next.toString();
    onChanged?.call();
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
              onChanged: (_) => onChanged?.call(),
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

class _PriceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final Color activeColor;
  final VoidCallback? onChanged;

  const _PriceField({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.activeColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0D1117);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    _DecimalCapFormatter(999999),
                  ],
                  onChanged: (_) => onChanged?.call(),
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val <= 0) return 'Required';
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

// Decimal formatter
class _DecimalCapFormatter extends TextInputFormatter {
  final double maxValue;
  const _DecimalCapFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (newValue.text.endsWith('.')) return newValue;
    final v = double.tryParse(newValue.text);
    if (v == null) return oldValue;
    if (v > maxValue) return oldValue;
    return newValue;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    _DecimalCapFormatter(999999),
                  ],
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

class _ChargesField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback? onChanged;

  const _ChargesField({
    required this.controller,
    required this.isDark,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0D1117);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
          Text(
            'Charges',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    _DecimalCapFormatter(999999),
                  ],
                  onChanged: (_) => onChanged?.call(),
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

class _PnLDisplay extends StatelessWidget {
  final double pnl;
  final bool isDark;

  const _PnLDisplay({
    required this.pnl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pnlColor =
        pnl >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4D6A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pnlColor.withOpacity(0.3)),
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
          Text(
            'Net P&L',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: pnlColor,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                // Uses formatShortPnL — displays K / L / Cr suffix
                child: Text(
                  formatShortPnL(pnl),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: pnlColor,
                  ),
                ),
              ),
              if (pnl != 0)
                Icon(
                  pnl > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: pnlColor,
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

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool isDark;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0D1117);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
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
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                Icon(
                  Icons.edit_calendar_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              DateFormat('hh:mm a').format(date),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
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
    final borderColor = widget.isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 18,
                color: textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Describe your trade thesis...',
                    hintStyle: TextStyle(color: textMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
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
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? widget.activeColor.withOpacity(0.13)
                      : (widget.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(30),
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

class _BottomBar extends StatelessWidget {
  final bool isDark;
  final Color activeColor;
  final bool isSubmitting;
  final bool isDeleting;
  final VoidCallback onSubmit;
  final VoidCallback onDelete;

  const _BottomBar({
    required this.isDark,
    required this.activeColor,
    required this.isSubmitting,
    required this.isDeleting,
    required this.onSubmit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_outlined,
                      size: 14, color: Colors.blue.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Educational use only — practice trading',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons row
            Row(
              children: [
                // Delete button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: isSubmitting || isDeleting ? null : onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF4D6A),
                        side: const BorderSide(
                            color: Color(0xFFFF4D6A), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isDeleting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF4D6A),
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 26),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Update button
                Expanded(
                  flex: 7,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting || isDeleting ? null : onSubmit,
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
                                  Icons.update_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Update Journal',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
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
