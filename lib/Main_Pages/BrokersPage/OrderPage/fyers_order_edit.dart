import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────
//  FyersOrderEditPage
//  Modify:  PUT  /fyers/orders        body: { id, type, qty, limitPrice, stopPrice, validity }
//  Cancel:  DELETE /fyers/orders/{order_id}
//
//  Fyers order type numeric codes:
//    1 = LIMIT   2 = MARKET   3 = SL-M (STOP)   4 = SL (STOPLIMIT)
//  Fyers validity: DAY | IOC | GTD
// ─────────────────────────────────────────────────────────────

// ── Fyers-specific order data model ──────────────────────────
class FyersOrderModel {
  final String orderId; // "id" from Fyers response
  final String symbol; // "NSE:RELIANCE-EQ" — fyers_symbol field
  final String
      transactionType; // "BUY" | "SELL" (side: 1 | -1, but we store as string)
  final int orderTypeCode; // 1=LIMIT 2=MARKET 3=SL-M 4=SL
  final String orderTypeLabel; // human-readable for display
  final int quantity;
  final double price; // limitPrice
  final double stopPrice; // stopPrice (trigger)
  final String validity; // DAY | IOC | GTD
  final String productType; // INTRADAY | CNC | MARGIN | CO | BO
  final String status; // OPEN | FILLED | CANCELLED | REJECTED etc.
  final double avgPrice;

  const FyersOrderModel({
    required this.orderId,
    required this.symbol,
    required this.transactionType,
    required this.orderTypeCode,
    required this.orderTypeLabel,
    required this.quantity,
    required this.price,
    required this.stopPrice,
    required this.validity,
    required this.productType,
    required this.status,
    required this.avgPrice,
  });

  /// Map human-readable label → Fyers numeric type code
  static int labelToCode(String label) {
    switch (label) {
      case 'LIMIT':
        return 1;
      case 'MARKET':
        return 2;
      case 'SL-M':
        return 3;
      case 'SL':
        return 4;
      default:
        return 2;
    }
  }

  static String codeToLabel(int code) {
    switch (code) {
      case 1:
        return 'LIMIT';
      case 2:
        return 'MARKET';
      case 3:
        return 'SL-M';
      case 4:
        return 'SL';
      default:
        return 'MARKET';
    }
  }
}

class FyersOrderEditPage extends StatefulWidget {
  final FyersOrderModel order;

  const FyersOrderEditPage({Key? key, required this.order}) : super(key: key);

  @override
  State<FyersOrderEditPage> createState() => _FyersOrderEditPageState();
}

class _FyersOrderEditPageState extends State<FyersOrderEditPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _stopPriceController;

  late String _orderTypeLabel; // human-readable selection
  late String _validity;

  bool _isModifying = false;
  bool _isCancelling = false;

  late AnimationController _pageAnimCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Derived ──────────────────────────────────────────────
  bool get _isBuy => widget.order.transactionType == 'BUY';
  Color get _activeColor =>
      _isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

  // Fyers: type 1=LIMIT or 4=SL needs limitPrice; type 3=SL-M or 4=SL needs stopPrice
  int get _selectedCode => FyersOrderModel.labelToCode(_orderTypeLabel);
  bool get _needsPrice =>
      _selectedCode == 1 || _selectedCode == 4; // LIMIT or SL
  bool get _needsStop => _selectedCode == 3 || _selectedCode == 4; // SL-M or SL

  static const List<String> _orderTypeLabels = [
    'MARKET',
    'LIMIT',
    'SL-M',
    'SL'
  ];
  static const List<String> _validities = ['DAY', 'IOC', 'GTD'];

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _qtyController = TextEditingController(text: o.quantity.toString());
    _priceController = TextEditingController(
        text: o.price > 0 ? o.price.toStringAsFixed(2) : '');
    _stopPriceController = TextEditingController(
        text: o.stopPrice > 0 ? o.stopPrice.toStringAsFixed(2) : '');
    _orderTypeLabel = FyersOrderModel.codeToLabel(o.orderTypeCode);
    _validity = o.validity;

    _pageAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim = CurvedAnimation(parent: _pageAnimCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _pageAnimCtrl, curve: Curves.easeOutCubic));
    _pageAnimCtrl.forward();
  }

  @override
  void dispose() {
    _pageAnimCtrl.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _stopPriceController.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────

  Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');
    return await user.getIdToken() ?? '';
  }

  Future<void> _modifyOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isModifying = true);
    try {
      final token = await _getToken();
      final baseUrl = dotenv.env['FYERS_ORDER_URL']!;
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 30)
        ..options.receiveTimeout = const Duration(seconds: 30);

      // Fyers PUT /fyers/orders — body has "id" (NOT in URL path)
      final body = <String, dynamic>{
        'order_id': widget.order.orderId, // server maps to { id: ... }
        'order_type': _orderTypeLabel, // server maps to numeric code
        'quantity': int.tryParse(_qtyController.text) ?? widget.order.quantity,
        'validity': _validity,
      };
      if (_needsPrice) {
        final p = double.tryParse(_priceController.text);
        if (p != null && p > 0) body['price'] = p; // server maps to limitPrice
      }
      if (_needsStop) {
        final s = double.tryParse(_stopPriceController.text);
        if (s != null && s > 0)
          body['stop_price'] = s; // server maps to stopPrice
      }

      final response = await dio.put(
        '$baseUrl/fyers/orders',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: body,
      );

      if (response.statusCode == 200) {
        _showSuccess('Order modified successfully');
        if (mounted) Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ??
          e.response?.data?['detail'] ??
          'Failed to modify order';
      _showError(msg.toString());
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isModifying = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await _showCancelConfirm();
    if (!confirmed) return;
    setState(() => _isCancelling = true);
    try {
      final token = await _getToken();
      final baseUrl = dotenv.env['FYERS_ORDER_URL']!;
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 30)
        ..options.receiveTimeout = const Duration(seconds: 30);

      // Fyers DELETE /fyers/orders/{order_id}
      final response = await dio.delete(
        '$baseUrl/fyers/orders/${widget.order.orderId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        _showSuccess('Order cancelled');
        if (mounted) Navigator.pop(context, 'cancelled');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ??
          e.response?.data?['detail'] ??
          'Failed to cancel order';
      _showError(msg.toString());
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<bool> _showCancelConfirm() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (_) => _FyCancelConfirmDialog(
            isDark: isDark,
            symbol: widget.order.symbol,
            orderId: widget.order.orderId,
          ),
        ) ??
        false;
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────

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
                _buildHeader(isDark),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // ── Fyers order info card ──────────────
                        _FyOrderInfoCard(
                            order: widget.order,
                            isDark: isDark,
                            activeColor: _activeColor),

                        const SizedBox(height: 24),

                        // ── Modify section header ──────────────
                        _FyLabel(
                            label: 'Modify Order',
                            isDark: isDark,
                            icon: Icons.edit_rounded),
                        const SizedBox(height: 14),

                        // ── Order type ─────────────────────────
                        _FyLabel(
                            label: 'Order Type',
                            isDark: isDark,
                            icon: Icons.tune_rounded),
                        const SizedBox(height: 10),
                        _FyChips(
                          options: _orderTypeLabels,
                          selected: _orderTypeLabel,
                          isDark: isDark,
                          activeColor: _activeColor,
                          onSelect: (v) => setState(() => _orderTypeLabel = v),
                        ),

                        const SizedBox(height: 22),

                        // ── Quantity ───────────────────────────
                        _FyLabel(
                            label: 'Quantity',
                            isDark: isDark,
                            icon: Icons.format_list_numbered_rounded),
                        const SizedBox(height: 10),
                        _FyEditQtyRow(
                          controller: _qtyController,
                          isDark: isDark,
                          activeColor: _activeColor,
                        ),

                        const SizedBox(height: 22),

                        // ── Limit price (LIMIT / SL) ───────────
                        if (_needsPrice) ...[
                          _FyLabel(
                              label: _orderTypeLabel == 'LIMIT'
                                  ? 'Limit Price'
                                  : 'Order Price',
                              isDark: isDark,
                              icon: Icons.currency_rupee_rounded),
                          const SizedBox(height: 10),
                          _FyPriceField(
                            label: 'Limit Price',
                            controller: _priceController,
                            isDark: isDark,
                            accentColor: _activeColor,
                          ),
                          const SizedBox(height: 22),
                        ],

                        // ── Stop price (SL-M / SL) ─────────────
                        if (_needsStop) ...[
                          _FyLabel(
                              label: 'Stop Price',
                              isDark: isDark,
                              icon: Icons.notifications_active_rounded),
                          const SizedBox(height: 10),
                          _FyPriceField(
                            label: 'Stop',
                            controller: _stopPriceController,
                            isDark: isDark,
                            accentColor: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 22),
                        ],

                        // ── Validity ───────────────────────────
                        _FyLabel(
                            label: 'Validity',
                            isDark: isDark,
                            icon: Icons.schedule_rounded),
                        const SizedBox(height: 10),
                        _FyChips(
                          options: _validities,
                          selected: _validity,
                          isDark: isDark,
                          activeColor: _activeColor,
                          onSelect: (v) => setState(() => _validity = v),
                        ),

                        const SizedBox(height: 22),

                        // ── Type code info badge ───────────────
                        _FyTypeCodeBadge(
                          isDark: isDark,
                          selectedLabel: _orderTypeLabel,
                          selectedCode: _selectedCode,
                        ),

                        const SizedBox(height: 22),

                        // ── Diff preview ───────────────────────
                        _FyDiffCard(
                          isDark: isDark,
                          original: widget.order,
                          newOrderTypeLabel: _orderTypeLabel,
                          newQty: int.tryParse(_qtyController.text) ??
                              widget.order.quantity,
                          newPrice: double.tryParse(_priceController.text) ?? 0,
                          newStopPrice:
                              double.tryParse(_stopPriceController.text) ?? 0,
                          newValidity: _validity,
                          activeColor: _activeColor,
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final bg = isDark ? const Color(0xFF12151C) : Colors.white;
    final divider = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1117);
    final chipBg =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF3F4F6);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: chipBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14, color: textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modify Order',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3)),
                    Text(
                      widget.order.symbol,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // Fyers badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('FYERS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8B5CF6),
                          letterSpacing: 1.0,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Order ID badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3)),
                ),
                child: Text(
                  '#${widget.order.orderId.length > 8 ? widget.order.orderId.substring(0, 8) : widget.order.orderId}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6366F1),
                    letterSpacing: 0.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: divider),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────
  Widget _buildBottomBar(bool isDark) {
    final bg = isDark ? const Color(0xFF12151C) : Colors.white;
    final divider = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.07);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: divider)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Row(
          children: [
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed:
                    (_isCancelling || _isModifying) ? null : _cancelOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(
                      color: _isCancelling
                          ? Colors.grey
                          : const Color(0xFFEF4444).withOpacity(0.5),
                      width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Color(0xFFEF4444), strokeWidth: 2))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.cancel_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Cancel Order',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_isModifying || _isCancelling) ? null : _modifyOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _activeColor.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isModifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Modify Order',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CANCEL CONFIRM DIALOG
// ═══════════════════════════════════════════════════════════════

class _FyCancelConfirmDialog extends StatelessWidget {
  final bool isDark;
  final String symbol;
  final String orderId;

  const _FyCancelConfirmDialog({
    required this.isDark,
    required this.symbol,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF12151C) : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: const Color(0xFFEF4444).withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 18),
            Text('Cancel Order?',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text(
              'This will cancel your $symbol order on Fyers. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                  height: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Order #${orderId.length > 10 ? orderId.substring(0, 10) : orderId}',
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white54 : Colors.black45,
                      side: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Keep',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Yes, Cancel',
                        style: TextStyle(fontWeight: FontWeight.w800)),
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

// ═══════════════════════════════════════════════════════════════
//  FYERS ORDER INFO CARD  (read-only)
// ═══════════════════════════════════════════════════════════════

class _FyOrderInfoCard extends StatelessWidget {
  final FyersOrderModel order;
  final bool isDark;
  final Color activeColor;

  const _FyOrderInfoCard({
    required this.order,
    required this.isDark,
    required this.activeColor,
  });

  Widget _kv(String k, String v, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                letterSpacing: 0.4)),
        const SizedBox(height: 3),
        Text(v,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ??
                    (isDark ? Colors.white : const Color(0xFF0D1117)))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final isBuy = order.transactionType == 'BUY';
    final txColor = isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: activeColor.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: txColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.transactionType,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: txColor)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(order.symbol,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.3)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(order.status))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _kv('Product', order.productType, isDark)),
              Expanded(
                  child: _kv(
                      'Order Type',
                      '${order.orderTypeLabel} (${order.orderTypeCode})',
                      isDark)),
              Expanded(child: _kv('Validity', order.validity, isDark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _kv('Quantity', order.quantity.toString(), isDark)),
              Expanded(
                  child: _kv(
                      'Limit Price',
                      order.price > 0
                          ? '₹${order.price.toStringAsFixed(2)}'
                          : 'MKT',
                      isDark)),
              Expanded(
                  child: _kv(
                      'Avg Price',
                      order.avgPrice > 0
                          ? '₹${order.avgPrice.toStringAsFixed(2)}'
                          : '—',
                      isDark,
                      valueColor: order.avgPrice > 0
                          ? (isDark ? Colors.white70 : Colors.black54)
                          : null)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'FILLED':
      case 'COMPLETE':
        return const Color(0xFF10B981);
      case 'OPEN':
      case 'PENDING':
      case 'TRIGGER PENDING':
        return const Color(0xFFF59E0B);
      case 'CANCELLED':
      case 'REJECTED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  TYPE CODE BADGE  (Fyers-specific — shows int code mapping)
// ═══════════════════════════════════════════════════════════════

class _FyTypeCodeBadge extends StatelessWidget {
  final bool isDark;
  final String selectedLabel;
  final int selectedCode;

  const _FyTypeCodeBadge({
    required this.isDark,
    required this.selectedLabel,
    required this.selectedCode,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final accent = const Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: accent),
          const SizedBox(width: 8),
          Text('Fyers type code: ',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$selectedCode ($selectedLabel)',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontFamily: 'monospace'),
            ),
          ),
          const Spacer(),
          Text('1=LIMIT  2=MKT  3=SL-M  4=SL',
              style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DIFF CARD
// ═══════════════════════════════════════════════════════════════

class _FyDiffCard extends StatelessWidget {
  final bool isDark;
  final FyersOrderModel original;
  final String newOrderTypeLabel;
  final int newQty;
  final double newPrice;
  final double newStopPrice;
  final String newValidity;
  final Color activeColor;

  const _FyDiffCard({
    required this.isDark,
    required this.original,
    required this.newOrderTypeLabel,
    required this.newQty,
    required this.newPrice,
    required this.newStopPrice,
    required this.newValidity,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final changes = <Map<String, String>>[];

    if (newQty != original.quantity) {
      changes.add({
        'field': 'Quantity',
        'from': original.quantity.toString(),
        'to': newQty.toString()
      });
    }
    if (newOrderTypeLabel != original.orderTypeLabel) {
      changes.add({
        'field': 'Order Type',
        'from': original.orderTypeLabel,
        'to': newOrderTypeLabel
      });
    }
    if (newValidity != original.validity) {
      changes.add(
          {'field': 'Validity', 'from': original.validity, 'to': newValidity});
    }
    if (newPrice > 0 && newPrice != original.price) {
      changes.add({
        'field': 'Limit Price',
        'from': original.price > 0
            ? '₹${original.price.toStringAsFixed(2)}'
            : 'MKT',
        'to': '₹${newPrice.toStringAsFixed(2)}',
      });
    }
    if (newStopPrice > 0 && newStopPrice != original.stopPrice) {
      changes.add({
        'field': 'Stop Price',
        'from': original.stopPrice > 0
            ? '₹${original.stopPrice.toStringAsFixed(2)}'
            : '—',
        'to': '₹${newStopPrice.toStringAsFixed(2)}',
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: changes.isEmpty
                ? (isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06))
                : activeColor.withOpacity(0.25),
            width: changes.isEmpty ? 1 : 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                changes.isEmpty
                    ? Icons.info_outline_rounded
                    : Icons.compare_arrows_rounded,
                size: 14,
                color: changes.isEmpty
                    ? (isDark ? Colors.white38 : Colors.black38)
                    : activeColor,
              ),
              const SizedBox(width: 6),
              Text(
                changes.isEmpty ? 'No changes yet' : 'Changes Preview',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: changes.isEmpty
                        ? (isDark ? Colors.white38 : Colors.black38)
                        : activeColor,
                    letterSpacing: 0.3),
              ),
              if (changes.isNotEmpty) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      '${changes.length} field${changes.length > 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: activeColor)),
                ),
              ],
            ],
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...changes.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(c['field']!,
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.w500)),
                      ),
                      Text(c['from']!,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          size: 12,
                          color: isDark ? Colors.white38 : Colors.black26),
                      const SizedBox(width: 8),
                      Text(c['to']!,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: activeColor)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS (Fyers-scoped with _Fy prefix)
// ═══════════════════════════════════════════════════════════════

class _FyLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final IconData? icon;

  const _FyLabel({required this.label, required this.isDark, this.icon});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
        ],
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8)),
      ],
    );
  }
}

class _FyChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final bool isDark;
  final Color activeColor;
  final void Function(String) onSelect;

  const _FyChips({
    required this.options,
    required this.selected,
    required this.isDark,
    required this.activeColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () {
            onSelect(opt);
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.13)
                  : (isDark ? const Color(0xFF1A1D26) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? activeColor.withOpacity(0.45)
                    : (isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(opt,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : (isDark ? Colors.white54 : Colors.black45),
                    letterSpacing: 0.3)),
          ),
        );
      }).toList(),
    );
  }
}

class _FyEditQtyRow extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color activeColor;

  const _FyEditQtyRow({
    required this.controller,
    required this.isDark,
    required this.activeColor,
  });

  @override
  State<_FyEditQtyRow> createState() => _FyEditQtyRowState();
}

class _FyEditQtyRowState extends State<_FyEditQtyRow> {
  void _change(int delta) {
    final cur = int.tryParse(widget.controller.text) ?? 1;
    final next = (cur + delta).clamp(1, 100000);
    widget.controller.text = next.toString();
    setState(() {});
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1A1D26) : Colors.white;
    final border = widget.isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);
    final text = widget.isDark ? Colors.white : const Color(0xFF0D1117);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          _FyBtn(
              icon: Icons.remove_rounded,
              bg: widget.isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              fg: widget.isDark ? Colors.white54 : Colors.black45,
              isLeft: true,
              onTap: () => _change(-1)),
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: text,
                  letterSpacing: -0.5),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '1',
                  hintStyle: TextStyle(
                      color: widget.isDark ? Colors.white24 : Colors.black26)),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final val = int.tryParse(v ?? '');
                if (val == null || val <= 0) return 'Required';
                return null;
              },
            ),
          ),
          _FyBtn(
              icon: Icons.add_rounded,
              bg: widget.activeColor.withOpacity(0.12),
              fg: widget.activeColor,
              isLeft: false,
              onTap: () => _change(1)),
        ],
      ),
    );
  }
}

class _FyBtn extends StatelessWidget {
  final IconData icon;
  final Color bg, fg;
  final bool isLeft;
  final VoidCallback onTap;

  const _FyBtn({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(15) : Radius.zero,
              right: !isLeft ? const Radius.circular(15) : Radius.zero,
            ),
          ),
          child: Icon(icon, size: 20, color: fg),
        ),
      );
}

class _FyPriceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final Color accentColor;

  const _FyPriceField({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1D26) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0D1117);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                  letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('₹',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: accentColor)),
              const SizedBox(width: 4),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: text),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
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
