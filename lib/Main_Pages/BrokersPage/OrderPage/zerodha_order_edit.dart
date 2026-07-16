import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optionxi/Main_Pages/BrokersPage/Zerodha/utils/zerodha_datamodel.dart';

// ─────────────────────────────────────────────────────────────
//  ZerodhaOrderEditPage
//  Supports: Modify existing order (pass [order]) or place new one
//  Calls PUT /zerodha/orders/{variety}/{orderId}
//  Calls DELETE /zerodha/orders/{variety}/{orderId}
// ─────────────────────────────────────────────────────────────

class ZerodhaOrderEditPage extends StatefulWidget {
  /// The order to modify. All fields are pre-filled.
  final OrderModel order;

  const ZerodhaOrderEditPage({Key? key, required this.order}) : super(key: key);

  @override
  State<ZerodhaOrderEditPage> createState() => _ZerodhaOrderEditPageState();
}

class _ZerodhaOrderEditPageState extends State<ZerodhaOrderEditPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _triggerController;

  late String _orderType;
  late String _validity;

  bool _isModifying = false;
  bool _isCancelling = false;

  late AnimationController _pageAnimCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // derived
  bool get _isBuy => widget.order.transactionType == 'BUY';
  Color get _activeColor =>
      _isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

  bool get _needsPrice => _orderType == 'LIMIT' || _orderType == 'SL';
  bool get _needsTrigger => _orderType == 'SL' || _orderType == 'SL-M';

  static const List<String> _orderTypes = ['MARKET', 'LIMIT', 'SL', 'SL-M'];
  static const List<String> _validities = ['DAY', 'IOC'];

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    _qtyController = TextEditingController(text: o.quantity.toString());
    _priceController = TextEditingController(
        text: o.price > 0 ? o.price.toStringAsFixed(2) : '');
    _triggerController = TextEditingController(
        text: o.triggerPrice > 0 ? o.triggerPrice.toStringAsFixed(2) : '');
    _orderType = o.orderType;
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
    _triggerController.dispose();
    super.dispose();
  }

  // ── API calls ──────────────────────────────────────────────

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
      final baseUrl = dotenv.env['ZERODHA_ORDER_URL']!;
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 30)
        ..options.receiveTimeout = const Duration(seconds: 30);

      final body = <String, dynamic>{
        'quantity': int.tryParse(_qtyController.text) ?? widget.order.quantity,
        'order_type': _orderType,
        'validity': _validity,
      };
      if (_needsPrice) {
        final p = double.tryParse(_priceController.text);
        if (p != null && p > 0) body['price'] = p;
      }
      if (_needsTrigger) {
        final t = double.tryParse(_triggerController.text);
        if (t != null && t > 0) body['trigger_price'] = t;
      }

      final variety =
          widget.order.variety.isNotEmpty ? widget.order.variety : 'regular';

      final response = await dio.put(
        '$baseUrl/orders/$variety/${widget.order.orderId}',
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
      final baseUrl = dotenv.env['ZERODHA_ORDER_URL']!;
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 30)
        ..options.receiveTimeout = const Duration(seconds: 30);

      final variety =
          widget.order.variety.isNotEmpty ? widget.order.variety : 'regular';

      final response = await dio.delete(
        '$baseUrl/orders/$variety/${widget.order.orderId}',
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
          builder: (_) => _CancelConfirmDialog(
            isDark: isDark,
            symbol: widget.order.tradingSymbol,
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
                        // ── Order info card (read-only) ──────────
                        _OrderInfoCard(
                            order: widget.order,
                            isDark: isDark,
                            activeColor: _activeColor),

                        const SizedBox(height: 24),

                        // ── Modify section header ────────────────
                        _ZLabel(
                            label: 'Modify Order',
                            isDark: isDark,
                            icon: Icons.edit_rounded),
                        const SizedBox(height: 14),

                        // ── Order type ───────────────────────────
                        _ZLabel(
                            label: 'Order Type',
                            isDark: isDark,
                            icon: Icons.tune_rounded),
                        const SizedBox(height: 10),
                        _ZChips(
                          options: _orderTypes,
                          selected: _orderType,
                          isDark: isDark,
                          activeColor: _activeColor,
                          onSelect: (v) => setState(() => _orderType = v),
                        ),

                        const SizedBox(height: 22),

                        // ── Quantity ─────────────────────────────
                        _ZLabel(
                            label: 'Quantity',
                            isDark: isDark,
                            icon: Icons.format_list_numbered_rounded),
                        const SizedBox(height: 10),
                        _EditQtyRow(
                          controller: _qtyController,
                          isDark: isDark,
                          activeColor: _activeColor,
                        ),

                        const SizedBox(height: 22),

                        // ── Price inputs (conditional) ───────────
                        if (_needsPrice) ...[
                          _ZLabel(
                              label: _orderType == 'LIMIT'
                                  ? 'Limit Price'
                                  : 'Order Price',
                              isDark: isDark,
                              icon: Icons.currency_rupee_rounded),
                          const SizedBox(height: 10),
                          _EditPriceField(
                            label: 'Price',
                            controller: _priceController,
                            isDark: isDark,
                            accentColor: _activeColor,
                          ),
                          const SizedBox(height: 22),
                        ],
                        if (_needsTrigger) ...[
                          _ZLabel(
                              label: 'Trigger Price',
                              isDark: isDark,
                              icon: Icons.notifications_active_rounded),
                          const SizedBox(height: 10),
                          _EditPriceField(
                            label: 'Trigger',
                            controller: _triggerController,
                            isDark: isDark,
                            accentColor: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 22),
                        ],

                        // ── Validity ─────────────────────────────
                        _ZLabel(
                            label: 'Validity',
                            isDark: isDark,
                            icon: Icons.schedule_rounded),
                        const SizedBox(height: 10),
                        _ZChips(
                          options: _validities,
                          selected: _validity,
                          isDark: isDark,
                          activeColor: _activeColor,
                          onSelect: (v) => setState(() => _validity = v),
                        ),

                        const SizedBox(height: 22),

                        // ── Live diff summary ────────────────────
                        _DiffCard(
                          isDark: isDark,
                          original: widget.order,
                          newOrderType: _orderType,
                          newQty: int.tryParse(_qtyController.text) ??
                              widget.order.quantity,
                          newPrice: double.tryParse(_priceController.text) ?? 0,
                          newTrigger:
                              double.tryParse(_triggerController.text) ?? 0,
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

  // ── Header ─────────────────────────────────────────────────
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
                      widget.order.tradingSymbol,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
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

  // ── Bottom bar ──────────────────────────────────────────────
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
            // Cancel order button
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
            // Modify button
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

class _CancelConfirmDialog extends StatelessWidget {
  final bool isDark;
  final String symbol;
  final String orderId;

  const _CancelConfirmDialog({
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
              'This will cancel your $symbol order. This action cannot be undone.',
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
//  ORDER INFO CARD  (read-only original values)
// ═══════════════════════════════════════════════════════════════

class _OrderInfoCard extends StatelessWidget {
  final OrderModel order;
  final bool isDark;
  final Color activeColor;

  const _OrderInfoCard({
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
          // Header row
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
                child: Text(order.tradingSymbol,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.4)),
              ),
              // Status chip
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
          // Info grid
          Row(
            children: [
              Expanded(child: _kv('Exchange', order.exchange, isDark)),
              Expanded(child: _kv('Product', order.product, isDark)),
              Expanded(child: _kv('Order Type', order.orderType, isDark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _kv('Quantity', order.quantity.toString(), isDark)),
              Expanded(
                  child: _kv(
                      'Price',
                      order.price > 0
                          ? '₹${order.price.toStringAsFixed(2)}'
                          : 'MKT',
                      isDark)),
              Expanded(
                  child: _kv(
                      'Avg Price',
                      order.averagePrice > 0
                          ? '₹${order.averagePrice.toStringAsFixed(2)}'
                          : '—',
                      isDark,
                      valueColor: order.averagePrice > 0
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
      case 'COMPLETE':
        return const Color(0xFF10B981);
      case 'OPEN':
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
//  DIFF CARD  (shows what will change)
// ═══════════════════════════════════════════════════════════════

class _DiffCard extends StatelessWidget {
  final bool isDark;
  final OrderModel original;
  final String newOrderType;
  final int newQty;
  final double newPrice;
  final double newTrigger;
  final String newValidity;
  final Color activeColor;

  const _DiffCard({
    required this.isDark,
    required this.original,
    required this.newOrderType,
    required this.newQty,
    required this.newPrice,
    required this.newTrigger,
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
        'to': newQty.toString(),
      });
    }
    if (newOrderType != original.orderType) {
      changes.add({
        'field': 'Order Type',
        'from': original.orderType,
        'to': newOrderType,
      });
    }
    if (newValidity != original.validity) {
      changes.add({
        'field': 'Validity',
        'from': original.validity,
        'to': newValidity,
      });
    }
    if (newPrice > 0 && newPrice != original.price) {
      changes.add({
        'field': 'Price',
        'from': original.price > 0
            ? '₹${original.price.toStringAsFixed(2)}'
            : 'MKT',
        'to': '₹${newPrice.toStringAsFixed(2)}',
      });
    }
    if (newTrigger > 0 && newTrigger != original.triggerPrice) {
      changes.add({
        'field': 'Trigger',
        'from': original.triggerPrice > 0
            ? '₹${original.triggerPrice.toStringAsFixed(2)}'
            : '—',
        'to': '₹${newTrigger.toStringAsFixed(2)}',
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
                        width: 72,
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
//  SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

class _ZLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final IconData? icon;

  const _ZLabel({required this.label, required this.isDark, this.icon});

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

class _ZChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final bool isDark;
  final Color activeColor;
  final void Function(String) onSelect;

  const _ZChips({
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

class _EditQtyRow extends StatefulWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color activeColor;

  const _EditQtyRow({
    required this.controller,
    required this.isDark,
    required this.activeColor,
  });

  @override
  State<_EditQtyRow> createState() => _EditQtyRowState();
}

class _EditQtyRowState extends State<_EditQtyRow> {
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
          _Btn(
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
          _Btn(
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

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color bg, fg;
  final bool isLeft;
  final VoidCallback onTap;

  const _Btn({
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

class _EditPriceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final Color accentColor;

  const _EditPriceField({
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
