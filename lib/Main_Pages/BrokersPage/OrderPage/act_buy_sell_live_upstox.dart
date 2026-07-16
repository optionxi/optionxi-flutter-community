import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meilisearch/meilisearch.dart' as meili;

// ─────────────────────────────────────────────────────────────
//  Theme tokens  (shared pattern)
// ─────────────────────────────────────────────────────────────

class _T {
  final bool dark;
  _T(this.dark);

  Color get bg => dark ? const Color(0xFF0C0E14) : const Color(0xFFF0F2F5);
  Color get sheet => dark ? const Color(0xFF13161F) : Colors.white;
  Color get card => dark ? const Color(0xFF1A1E2A) : const Color(0xFFF7F8FC);
  Color get chip => dark ? const Color(0xFF222537) : const Color(0xFFEEF0F5);
  Color get div => dark ? const Color(0xFF1F2235) : const Color(0xFFE8EAEF);
  Color get divLight =>
      dark ? const Color(0xFF252839) : const Color(0xFFF0F2F5);

  Color get t1 => dark ? Colors.white : const Color(0xFF0D1117);
  Color get t2 => dark ? const Color(0xFF8B90A7) : const Color(0xFF5A6070);
  Color get t3 => dark ? const Color(0xFF4A4F68) : const Color(0xFFB0B5C8);

  // Upstox brand purple accent for UI highlights
  static const buy = Color(0xFF1DB954);
  static const sell = Color(0xFFFF5252);
  static const amber = Color(0xFFF59E0B);
  static const blue = Color(0xFF5C33F6); // Upstox purple
  static const ce = Color(0xFF6C63FF);
  static const pe = Color(0xFFFF6584);
}

// ─────────────────────────────────────────────────────────────
//  Instrument helpers
// ─────────────────────────────────────────────────────────────

Color _typeColor(String? type) {
  switch (type) {
    case 'stock':
      return _T.blue;
    case 'option':
      return _T.ce;
    case 'future':
      return _T.amber;
    case 'etf':
      return const Color(0xFF34D399);
    case 'currency':
      return const Color(0xFFA78BFA);
    case 'commodity':
      return const Color(0xFFF97316);
    default:
      return _T.blue;
  }
}

String _optLabel(Map<String, dynamic> doc) {
  final type = doc['type'] as String? ?? '';
  final optType = doc['option_type'] as String?;
  if (type == 'option' && optType != null) return optType;
  return type.isEmpty ? '?' : type.toUpperCase();
}

Color _optColor(Map<String, dynamic> doc) {
  final type = doc['type'] as String? ?? '';
  final optTy = doc['option_type'] as String?;
  if (type == 'option') return optTy == 'CE' ? _T.ce : _T.pe;
  return _typeColor(type);
}

// Upstox uses `trading_symbol` and `instrument_key`
String _sym(Map<String, dynamic> s) =>
    (s['trading_symbol'] ?? s['tradingsymbol'] ?? s['symbol'] ?? '')
        .toString()
        .trim();

bool _isFno(Map<String, dynamic>? doc) {
  if (doc == null) return false;
  final t = doc['type'] as String? ?? '';
  return t == 'option' || t == 'future';
}

// ─────────────────────────────────────────────────────────────
//  Upstox product / order type maps
// ─────────────────────────────────────────────────────────────

// Upstox product codes: I = Intraday, D = Delivery, CO, OCO
const _upstoxProducts = ['I', 'D', 'CO'];
const _upstoxProductLabels = {'I': 'MIS', 'D': 'CNC', 'CO': 'CO'};
const _upstoxProductHints = {
  'I': 'Intraday · auto-squares at 3:20 PM',
  'D': 'Delivery · held in demat',
  'CO': 'Cover Order · with mandatory SL',
};

// Upstox order types match Zerodha strings
const _orderTypes = ['Market', 'Limit', 'SL', 'SL-M'];
const _orderTypeDesc = {
  'Market': 'Executes immediately at best available price.',
  'Limit': 'Executes only at your specified price or better.',
  'SL': 'Stop-loss limit — triggers at stop price, executes at limit.',
  'SL-M': 'Stop-loss market — triggers at stop, exits at market.',
};

// ─────────────────────────────────────────────────────────────
//  Margin model
// ─────────────────────────────────────────────────────────────

class _MarginInfo {
  final double required;
  final double available;
  final double brokerage;
  final double stt;
  final double exchTxn;
  final double gst;
  final double sebi;
  final double stamp;

  const _MarginInfo({
    required this.required,
    required this.available,
    required this.brokerage,
    required this.stt,
    required this.exchTxn,
    required this.gst,
    required this.sebi,
    required this.stamp,
  });

  double get totalCharges => brokerage + stt + exchTxn + gst + sebi + stamp;
  bool get sufficient => available >= required;
  double get shortfall => (required - available).clamp(0.0, double.infinity);
}

// ═══════════════════════════════════════════════════════════════
//  MAIN ORDER PAGE
// ═══════════════════════════════════════════════════════════════

class UpstoxOrderPage extends StatefulWidget {
  final String? stockname;
  final String? segment;
  final bool tosell;

  const UpstoxOrderPage({
    Key? key,
    this.stockname,
    this.segment,
    this.tosell = false,
  }) : super(key: key);

  @override
  State<UpstoxOrderPage> createState() => _UpstoxOrderPageState();
}

class _UpstoxOrderPageState extends State<UpstoxOrderPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _triggerCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Map<String, dynamic>? _stock;
  String _mode = 'BUY';
  String _product = 'D'; // Upstox: I | D | CO
  String _orderType = 'Market';
  String _validity = 'DAY';
  bool _placing = false;
  bool _showAdvanced = false;
  bool _showOrderTypeInfo = false;
  bool _loadingMargin = false;
  _MarginInfo? _margin;
  bool _marginExpanded = false;

  static const _validities = ['DAY', 'IOC'];

  bool get _needsPrice => _orderType == 'Limit' || _orderType == 'SL';
  bool get _needsTrigger => _orderType == 'SL' || _orderType == 'SL-M';
  Color get _ac => _mode == 'BUY' ? _T.buy : _T.sell;
  bool get _fno => _isFno(_stock);

  // Upstox uses instrument_key for API calls
  String get _instrumentKey => (_stock?['instrument_key'] as String?) ?? '';

  // Exchange is embedded in instrument_key prefix (NSE_EQ|..., NSE_FO|...)
  String get _exchangeLabel {
    final key = _instrumentKey;
    if (key.startsWith('NSE')) return 'NSE';
    if (key.startsWith('BSE')) return 'BSE';
    if (key.startsWith('MCX')) return 'MCX';
    return (_stock?['exchange'] as String?) ?? 'NSE';
  }

  // Upstox order_type API string
  String get _orderTypeApi {
    switch (_orderType) {
      case 'Market':
        return 'MARKET';
      case 'Limit':
        return 'LIMIT';
      case 'SL':
        return 'SL';
      case 'SL-M':
        return 'SL-M';
      default:
        return 'MARKET';
    }
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.tosell ? 'SELL' : 'BUY';

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    if (widget.stockname != null) {
      _stock = {
        'trading_symbol': widget.stockname,
        'symbol': widget.stockname,
        'name': widget.stockname,
        'type': widget.segment == 'FNO' ? 'future' : 'stock',
        'instrument_key': widget.segment == 'FNO'
            ? 'NSE_FO|${widget.stockname}'
            : 'NSE_EQ|${widget.stockname}',
      };
      if (widget.segment == 'FNO') _product = 'I';
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMargin());
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _triggerCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSearch() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => _UpstoxSearchPage(
          meiliClient: meili.MeiliSearchClient(
            dotenv.env['MELIESEARCH_URL']!,
            dotenv.env['MELIE_API_KEY']!,
          ),
        ),
        transitionsBuilder: (_, a1, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    if (result != null && mounted) _applyStock(result);
  }

  void _applyStock(Map<String, dynamic> s) {
    setState(() {
      _stock = s;
      final type = (s['type'] as String?) ?? '';
      if (type == 'option' || type == 'future') {
        _product = 'I';
        final lot = (s['lot_size'] as num?)?.toInt();
        if (lot != null && lot > 0) _qtyCtrl.text = lot.toString();
      } else {
        _product = 'D';
        _qtyCtrl.text = '1';
      }
      _margin = null;
    });
    HapticFeedback.mediumImpact();
    _fetchMargin();
  }

  Future<void> _fetchMargin() async {
    if (_stock == null || _instrumentKey.isEmpty) return;
    setState(() {
      _loadingMargin = true;
      _margin = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loadingMargin = false);
        return;
      }
      final token = await user.getIdToken();
      final baseUrl = dotenv.env['UPSTOX_ORDER_URL']!;
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 15)
        ..options.receiveTimeout = const Duration(seconds: 15);

      final qty = int.tryParse(_qtyCtrl.text) ?? 1;
      final price = double.tryParse(_priceCtrl.text) ?? 0;

      Response? marginResp, fundsResp, chargesResp;

      // POST /upstox/margins/orders  — basket margin
      try {
        marginResp = await dio.post(
          '$baseUrl/upstox/margins/orders',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
          data: [
            {
              'instrument_token': _instrumentKey,
              'quantity': qty,
              'product': _product,
              'transaction_type': _mode,
              'order_type': _orderTypeApi,
              'price': price,
              'trigger_price': 0,
            }
          ],
        );
      } catch (_) {}

      // GET /upstox/user/funds-and-margins
      try {
        fundsResp = await dio.get(
          '$baseUrl/upstox/user/funds-and-margins',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {}

      // POST /upstox/charges/orders — brokerage estimate
      try {
        chargesResp = await dio.post(
          '$baseUrl/upstox/charges/orders',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
          data: {
            'instrument_token': _instrumentKey,
            'quantity': qty,
            'product': _product,
            'transaction_type': _mode,
            'price': price > 0 ? price : 100.0,
          },
        );
      } catch (_) {}

      double req = 0,
          avail = 0,
          brok = 0,
          stt = 0,
          etxn = 0,
          gst = 0,
          sebi = 0,
          stamp = 0;

      // Upstox margin response: data.final_margin
      if (marginResp?.statusCode == 200) {
        final d = marginResp!.data?['data'];
        req = ((d?['final_margin'] ?? 0) as num).toDouble();
      }

      // Upstox funds: data.equity.available_margin or data.commodity.available_margin
      if (fundsResp?.statusCode == 200) {
        final d = fundsResp!.data?['data'];
        final isCom = _exchangeLabel == 'MCX';
        final seg = isCom ? d['commodity'] : d['equity'];
        avail = ((seg?['available_margin'] ?? 0) as num).toDouble();
      }

      // Upstox charges: data.charges.*
      if (chargesResp?.statusCode == 200) {
        final ch = chargesResp!.data?['data']?['charges'];
        brok = ((ch?['brokerage'] ?? 0) as num).toDouble();
        stt = ((ch?['stt_ctt'] ?? 0) as num).toDouble();
        etxn = ((ch?['transaction_charges'] ?? 0) as num).toDouble();
        gst = ((ch?['gst']?['total'] ?? 0) as num).toDouble();
        sebi = ((ch?['sebi_turnover_charges'] ?? 0) as num).toDouble();
        stamp = ((ch?['stamp_duty'] ?? 0) as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _margin = _MarginInfo(
              required: req,
              available: avail,
              brokerage: brok,
              stt: stt,
              exchTxn: etxn,
              gst: gst,
              sebi: sebi,
              stamp: stamp);
          _loadingMargin = false;
        });
      }
    } catch (e) {
      debugPrint('Upstox margin error: $e');
      if (mounted) setState(() => _loadingMargin = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_stock == null || _instrumentKey.isEmpty) {
      _snack('Select an instrument first.', err: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      final token = await user.getIdToken();
      final baseUrl = dotenv.env['UPSTOX_ORDER_URL']!;
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 30)
        ..options.receiveTimeout = const Duration(seconds: 30);

      // Upstox place order body
      final body = <String, dynamic>{
        'instrument_token': _instrumentKey,
        'quantity': int.tryParse(_qtyCtrl.text) ?? 1,
        'product': _product,
        'order_type': _orderTypeApi,
        'transaction_type': _mode,
        'price': 0.0,
        'trigger_price': 0.0,
        'validity': _validity,
        'disclosed_quantity': 0,
        'is_amo': false,
      };
      if (_needsPrice) {
        final p = double.tryParse(_priceCtrl.text);
        if (p != null) body['price'] = p;
      }
      if (_needsTrigger) {
        final tp = double.tryParse(_triggerCtrl.text);
        if (tp != null) body['trigger_price'] = tp;
      }

      final resp = await dio.post(
        '$baseUrl/upstox/orders',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: body,
      );

      if (resp.statusCode == 201) {
        _showSuccess(resp.data?['data']?['order_id']?.toString() ?? '');
      } else {
        throw Exception('Status ${resp.statusCode}');
      }
    } on DioException catch (e) {
      _snack(
          (e.response?.data?['error'] ??
                  e.response?.data?['detail'] ??
                  'Failed to place order')
              .toString(),
          err: true);
    } catch (e) {
      _snack('Error: $e', err: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? _T.sell : _T.buy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String orderId) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SuccessDialog(
          orderId: orderId,
          mode: _mode,
          symbol: _stock != null ? _sym(_stock!) : '',
          activeColor: _ac,
          onDone: () {
            Navigator.pop(context);
            Navigator.pop(context);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _T(isDark);
    return Scaffold(
      backgroundColor: t.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(children: [
              _buildHeader(t),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildInstrumentTile(t),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildQtyPrice(t),
                              const SizedBox(height: 18),
                              _buildOrderTypeSection(t),
                              const SizedBox(height: 18),
                              _buildProductSection(t),
                              const SizedBox(height: 18),
                              _buildExchangeRow(t),
                              const SizedBox(height: 16),
                              _buildMarginCard(t),
                              const SizedBox(height: 12),
                              _buildAdvancedToggle(t),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                child: _showAdvanced
                                    ? _buildAdvancedContent(t)
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 24),
                            ]),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(t),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_T t) {
    return Container(
      color: t.sheet,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: t.chip, borderRadius: BorderRadius.circular(11)),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 13, color: t.t2)),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Place Order',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: t.t1,
                  letterSpacing: -0.3)),
          Text('Upstox · Live', style: TextStyle(fontSize: 11, color: t.t3)),
        ])),
        const SizedBox(width: 12),
        _BsToggle(
            t: t,
            mode: _mode,
            onToggle: (v) => setState(() {
                  _mode = v;
                  _fetchMargin();
                })),
      ]),
    );
  }

  Widget _buildInstrumentTile(_T t) {
    return GestureDetector(
      onTap: _openSearch,
      child: Container(
        color: t.sheet,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: _stock == null ? _emptyInstrument(t) : _filledInstrument(t),
      ),
    );
  }

  Widget _emptyInstrument(_T t) => Row(children: [
        Icon(Icons.search_rounded, size: 20, color: t.t3),
        const SizedBox(width: 12),
        Expanded(
            child: Text('Search stocks, F&O, ETFs…',
                style: TextStyle(
                    fontSize: 15, color: t.t3, fontWeight: FontWeight.w500))),
      ]);

  Widget _filledInstrument(_T t) {
    final name = _sym(_stock!);
    final expiry = _stock!['expiry'] as String?;
    final strike = (_stock!['strike_price'] as num?)?.toDouble();
    final type = _stock!['type'] as String? ?? '';
    final isOption = type == 'option';
    final isFuture = type == 'future';
    final label = _optLabel(_stock!);
    final color = _optColor(_stock!);

    return Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (isOption || isFuture) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.3)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
              child: Text(name,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: t.t1,
                      letterSpacing: -0.4),
                  overflow: TextOverflow.ellipsis)),
        ]),
        if (isOption || isFuture) ...[
          const SizedBox(height: 3),
          Row(children: [
            if (expiry != null)
              Text('Exp $expiry', style: TextStyle(fontSize: 12, color: t.t2)),
            if (expiry != null && strike != null && strike > 0)
              Text('  ·  @ ${strike.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: t.t2)),
          ]),
        ] else if ((_stock!['name'] as String? ?? '').isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(_stock!['name'] as String,
              style: TextStyle(fontSize: 12, color: t.t2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ])),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: _openSearch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
              color: t.chip,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: t.div)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.swap_horiz_rounded, size: 14, color: t.t2),
            const SizedBox(width: 5),
            Text('Change',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: t.t2)),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildQtyPrice(_T t) => Row(children: [
        Expanded(
            child: _QtyField(
                t: t, ac: _ac, ctrl: _qtyCtrl, onChanged: _fetchMargin)),
        const SizedBox(width: 12),
        Expanded(
            child: _PriceField(
                t: t,
                ac: _ac,
                ctrl: _priceCtrl,
                needsPrice: _needsPrice,
                orderType: _orderType)),
      ]);

  Widget _buildOrderTypeSection(_T t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Order type',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.t3,
                letterSpacing: 0.4)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _showOrderTypeInfo = !_showOrderTypeInfo),
          child: Text(_showOrderTypeInfo ? 'Hide info' : "What's this?",
              style: TextStyle(
                  fontSize: 11,
                  color: _showOrderTypeInfo ? _T.blue : t.t3,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 8),
      Container(
        height: 42,
        decoration: BoxDecoration(
            color: t.chip,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: t.div)),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: _orderTypes.map((type) {
            final active = type == _orderType;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _orderType = type;
                    if (!(_orderType == 'Limit' || _orderType == 'SL'))
                      _priceCtrl.clear();
                    if (!(_orderType == 'SL' || _orderType == 'SL-M'))
                      _triggerCtrl.clear();
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: active ? t.sheet : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 1))
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(type,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? _ac : t.t2,
                          letterSpacing: active ? 0.1 : 0)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _showOrderTypeInfo
            ? Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: _T.blue.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _T.blue.withOpacity(0.12))),
                child: Column(
                    children: _orderTypes
                        .map((type) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width: 46,
                                        child: Text(type,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: type == _orderType
                                                    ? _ac
                                                    : _T.blue))),
                                    Expanded(
                                        child: Text(_orderTypeDesc[type]!,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: t.t2,
                                                height: 1.45))),
                                  ]),
                            ))
                        .toList()),
              )
            : const SizedBox.shrink(),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _needsTrigger
            ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _TriggerField(t: t, ctrl: _triggerCtrl))
            : const SizedBox.shrink(),
      ),
    ]);
  }

  Widget _buildProductSection(_T t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Product',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.t3,
              letterSpacing: 0.4)),
      const SizedBox(height: 8),
      Row(
          children: _upstoxProducts.asMap().entries.map((e) {
        final p = e.value;
        final isLast = e.key == _upstoxProducts.length - 1;
        final active = p == _product;
        return Expanded(
            child: GestureDetector(
          onTap: () {
            setState(() => _product = p);
            HapticFeedback.selectionClick();
            _fetchMargin();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(right: isLast ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: active ? _ac.withOpacity(0.1) : t.card,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: active ? _ac.withOpacity(0.4) : t.div,
                    width: active ? 1.5 : 1)),
            child: Text(_upstoxProductLabels[p] ?? p,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? _ac : t.t2)),
          ),
        ));
      }).toList()),
      const SizedBox(height: 5),
      Text(_upstoxProductHints[_product] ?? '',
          style: TextStyle(fontSize: 11, color: t.t3)),
    ]);
  }

  Widget _buildExchangeRow(_T t) {
    const exchColors = {
      'NSE': Color(0xFF387ED1),
      'BSE': Color(0xFF34D399),
      'MCX': Color(0xFFF97316),
    };
    final ec = exchColors[_exchangeLabel] ?? _T.blue;
    return Row(children: [
      Text('Exchange',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.t3,
              letterSpacing: 0.4)),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: ec.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ec.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: ec, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(_exchangeLabel,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: ec)),
        ]),
      ),
      const SizedBox(width: 6),
      Icon(Icons.lock_outline_rounded, size: 11, color: t.t3),
      const SizedBox(width: 3),
      Text('From instrument', style: TextStyle(fontSize: 10, color: t.t3)),
    ]);
  }

  Widget _buildMarginCard(_T t) => _MarginCard(
        t: t,
        ac: _ac,
        loading: _loadingMargin,
        margin: _margin,
        stockSelected: _stock != null,
        isFno: _fno,
        expanded: _marginExpanded,
        onToggleExpand: () =>
            setState(() => _marginExpanded = !_marginExpanded),
      );

  Widget _buildAdvancedToggle(_T t) {
    return GestureDetector(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.div)),
        child: Row(children: [
          Icon(Icons.tune_rounded, size: 14, color: t.t3),
          const SizedBox(width: 8),
          Text('Advanced options',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: t.t2)),
          const Spacer(),
          if (_showAdvanced)
            Text('Validity: $_validity',
                style: TextStyle(fontSize: 11, color: t.t3)),
          const SizedBox(width: 6),
          AnimatedRotation(
              turns: _showAdvanced ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: t.t3)),
        ]),
      ),
    );
  }

  Widget _buildAdvancedContent(_T t) {
    final expiry = _stock?['expiry'] as String?;
    final strike = (_stock?['strike_price'] as num?)?.toDouble();
    final lotSize = (_stock?['lot_size'] as num?)?.toInt();
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text);
    final trigger = double.tryParse(_triggerCtrl.text);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.div)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Validity',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.t3,
                letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Row(
            children: _validities.asMap().entries.map((e) {
          final v = e.value;
          final isLast = e.key == _validities.length - 1;
          final active = v == _validity;
          return Expanded(
              child: GestureDetector(
            onTap: () {
              setState(() => _validity = v);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: EdgeInsets.only(right: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: active ? _ac.withOpacity(0.1) : t.sheet,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: active ? _ac.withOpacity(0.4) : t.div,
                      width: active ? 1.5 : 1)),
              child: Text(v,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? _ac : t.t2)),
            ),
          ));
        }).toList()),
        const SizedBox(height: 16),
        Divider(color: t.div, height: 1),
        const SizedBox(height: 12),
        Text('Order summary',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: t.t3,
                letterSpacing: 0.4)),
        const SizedBox(height: 10),
        _sumRow(t, 'Symbol', _sym(_stock ?? {})),
        _sumRow(
            t, 'Instrument key', _instrumentKey.isEmpty ? '—' : _instrumentKey),
        _sumRow(t, 'Mode', _mode),
        _sumRow(t, 'Exchange', _exchangeLabel),
        _sumRow(t, 'Product',
            '${_upstoxProductLabels[_product] ?? _product} ($_product)'),
        _sumRow(t, 'Order type', _orderType),
        _sumRow(t, 'Validity', _validity),
        _sumRow(t, 'Quantity', qty > 0 ? qty.toString() : '—'),
        if (expiry != null) _sumRow(t, 'Expiry', expiry),
        if (strike != null && strike > 0)
          _sumRow(t, 'Strike', '₹${strike.toStringAsFixed(2)}'),
        if (lotSize != null && lotSize > 0)
          _sumRow(t, 'Lot size', lotSize.toString()),
        if (price != null && price > 0)
          _sumRow(t, 'Price', '₹${price.toStringAsFixed(2)}'),
        if (trigger != null && trigger > 0)
          _sumRow(t, 'Trigger', '₹${trigger.toStringAsFixed(2)}'),
      ]),
    );
  }

  Widget _sumRow(_T t, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.5),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k,
              style: TextStyle(
                  fontSize: 12, color: t.t2, fontWeight: FontWeight.w500)),
          Text(v,
              style: TextStyle(
                  fontSize: 12, color: t.t1, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _buildBottomBar(_T t) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
            color: t.sheet, border: Border(top: BorderSide(color: t.div))),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: _T.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded,
                  size: 13, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Live trading — real money at risk. Verify all details.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade600,
                          fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _placing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _ac,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _ac.withOpacity(0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              child: _placing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('${_mode == 'BUY' ? 'Buy' : 'Sell'} via Upstox',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MARGIN CARD
// ═══════════════════════════════════════════════════════════════

class _MarginCard extends StatelessWidget {
  final _T t;
  final Color ac;
  final bool loading;
  final _MarginInfo? margin;
  final bool stockSelected, isFno, expanded;
  final VoidCallback onToggleExpand;
  const _MarginCard(
      {required this.t,
      required this.ac,
      required this.loading,
      required this.margin,
      required this.stockSelected,
      required this.isFno,
      required this.expanded,
      required this.onToggleExpand});

  String _f(double v) => '₹${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.div)),
      child: Column(children: [
        InkWell(
          onTap: (stockSelected && !loading && margin != null)
              ? onToggleExpand
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 14, color: t.t3),
              const SizedBox(width: 7),
              Text('Margin & Charges',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: t.t2)),
              const Spacer(),
              if (loading)
                Row(children: [
                  SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: t.t3)),
                  const SizedBox(width: 6),
                  Text('Calculating…',
                      style: TextStyle(fontSize: 11, color: t.t3)),
                ])
              else if (!stockSelected)
                Text('Select instrument',
                    style: TextStyle(fontSize: 11, color: t.t3))
              else if (margin != null) ...[
                if (!margin!.sufficient)
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: _T.sell.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5)),
                      child: const Text('Low funds',
                          style: TextStyle(
                              fontSize: 10,
                              color: _T.sell,
                              fontWeight: FontWeight.w700))),
                const SizedBox(width: 6),
                AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: t.t3)),
              ],
            ]),
          ),
        ),
        if (!loading && margin != null) ...[
          Divider(height: 1, color: t.div),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: _StatBox(
                        t: t,
                        label: 'Required',
                        value: _f(margin!.required),
                        sub: isFno ? 'Margin' : 'Est.',
                        color: ac)),
                const SizedBox(width: 8),
                Expanded(
                    child: _StatBox(
                        t: t,
                        label: 'Available',
                        value: _f(margin!.available),
                        sub: margin!.sufficient ? '✓ Sufficient' : '✗ Low',
                        color: margin!.sufficient ? _T.buy : _T.sell)),
                const SizedBox(width: 8),
                Expanded(
                    child: _StatBox(
                        t: t,
                        label: 'Charges',
                        value: _f(margin!.totalCharges),
                        sub: 'Est. total',
                        color: t.t2)),
              ]),
              if (!margin!.sufficient) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _T.sell.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _T.sell.withOpacity(0.2))),
                  child: Row(children: [
                    const Icon(Icons.warning_rounded, size: 13, color: _T.sell),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Add ${_f(margin!.shortfall)} more funds to proceed.',
                            style: const TextStyle(
                                fontSize: 11,
                                color: _T.sell,
                                fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: expanded
                    ? Column(children: [
                        const SizedBox(height: 12),
                        Divider(color: t.div, height: 1),
                        const SizedBox(height: 10),
                        _cRow(t, 'Brokerage', _f(margin!.brokerage),
                            bold: true),
                        _cRow(t, 'STT / CTT', _f(margin!.stt)),
                        _cRow(t, 'Transaction charge', _f(margin!.exchTxn)),
                        _cRow(t, 'GST (18%)', _f(margin!.gst)),
                        _cRow(t, 'SEBI turnover charges', _f(margin!.sebi)),
                        _cRow(t, 'Stamp duty', _f(margin!.stamp)),
                        Divider(color: t.div, height: 16),
                        _cRow(t, 'Total charges', _f(margin!.totalCharges),
                            bold: true, highlight: true),
                      ])
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _cRow(_T t, String k, String v,
          {bool bold = false, bool highlight = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.5),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(k,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: highlight ? t.t1 : (bold ? t.t2 : t.t3))),
            Text(v,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    color: highlight ? t.t1 : (bold ? t.t2 : t.t3))),
          ]));
}

class _StatBox extends StatelessWidget {
  final _T t;
  final String label, value, sub;
  final Color color;
  const _StatBox(
      {required this.t,
      required this.label,
      required this.value,
      required this.sub,
      required this.color});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: t.t3, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 1),
        Text(sub, style: TextStyle(fontSize: 9, color: t.t3)),
      ]);
}

// ═══════════════════════════════════════════════════════════════
//  BUY/SELL TOGGLE
// ═══════════════════════════════════════════════════════════════

class _BsToggle extends StatelessWidget {
  final _T t;
  final String mode;
  final void Function(String) onToggle;
  const _BsToggle(
      {required this.t, required this.mode, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: t.chip,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: t.div)),
      child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['BUY', 'SELL'].map((m) {
            final active = mode == m;
            final color = m == 'BUY' ? _T.buy : _T.sell;
            return GestureDetector(
              onTap: () {
                onToggle(m);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
                decoration: BoxDecoration(
                    color:
                        active ? color.withOpacity(0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: active
                            ? color.withOpacity(0.45)
                            : Colors.transparent,
                        width: 1.5)),
                child: Text(m,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                        color: active ? color : t.t3,
                        letterSpacing: 0.3)),
              ),
            );
          }).toList()),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  UPSTOX SEARCH PAGE  —  index: stocks_upstox
// ═══════════════════════════════════════════════════════════════

class _UpstoxSearchPage extends StatefulWidget {
  final meili.MeiliSearchClient meiliClient;
  const _UpstoxSearchPage({required this.meiliClient});
  @override
  State<_UpstoxSearchPage> createState() => _UpstoxSearchPageState();
}

class _UpstoxSearchPageState extends State<_UpstoxSearchPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String _segment = 'All';
  String? _exchange;
  String? _expiry;

  static const _segments = [
    'All',
    'Stocks',
    'Options',
    'Futures',
    'ETF',
    'Currency',
    'Commodity'
  ];
  static const _exchanges = ['NSE', 'BSE', 'MCX'];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _focus.requestFocus();
    });
    _search('');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? get _segFilter {
    switch (_segment) {
      case 'Stocks':
        return 'type = "stock"';
      case 'Options':
        return 'type = "option"';
      case 'Futures':
        return 'type = "future"';
      case 'ETF':
        return 'type = "etf"';
      case 'Currency':
        return 'type = "currency"';
      case 'Commodity':
        return 'type = "commodity"';
      default:
        return null;
    }
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final filters = <String>[];
      if (_segFilter != null) filters.add(_segFilter!);
      if (_exchange != null) filters.add('exchange = "$_exchange"');

      if (_expiry == 'weekly') {
        final now = DateTime.now();
        filters.add(
            'expiry_ts >= ${now.millisecondsSinceEpoch ~/ 1000} AND expiry_ts <= ${now.add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000}');
      } else if (_expiry == 'monthly') {
        final now = DateTime.now();
        final end = DateTime(now.year, now.month + 1, 0);
        filters.add(
            'expiry_ts >= ${now.millisecondsSinceEpoch ~/ 1000} AND expiry_ts <= ${end.millisecondsSinceEpoch ~/ 1000}');
      }

      // Upstox index: stocks_upstox
      final res = await widget.meiliClient.index('stocks_upstox').search(
          q.trim(),
          meili.SearchQuery(
            filter: filters.isNotEmpty ? filters.join(' AND ') : null,
            attributesToRetrieve: [
              'id', 'trading_symbol', 'name', 'exchange', 'type',
              'option_type', 'expiry', 'expiry_ts', 'strike_price', 'lot_size',
              'instrument_key', // ← Upstox primary key for API calls
              'underlying_symbol', 'weekly',
            ],
            limit: q.trim().isEmpty ? 20 : 15,
          ));

      final hits = res.hits.cast<Map<String, dynamic>>();
      final ql = q.trim().toLowerCase();

      if (ql.isNotEmpty) {
        hits.sort((a, b) {
          final as_ = _sym(a).toLowerCase(), bs_ = _sym(b).toLowerCase();
          if (as_ == ql && bs_ != ql) return -1;
          if (bs_ == ql && as_ != ql) return 1;
          if (as_.startsWith(ql) && !bs_.startsWith(ql)) return -1;
          if (bs_.startsWith(ql) && !as_.startsWith(ql)) return 1;
          return 0;
        });
      }

      if (mounted)
        setState(() {
          _results = hits;
          _searching = false;
        });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _openOptionChain() {
    Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => _OptionChainPage(
            underlying: _ctrl.text.trim().isNotEmpty
                ? _ctrl.text.trim().toUpperCase()
                : null,
            meiliClient: widget.meiliClient,
            onSelect: (doc) {
              Navigator.pop(context);
              Navigator.pop(context, doc);
            },
          ),
          transitionsBuilder: (_, a1, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _T(isDark);
    final showFnoExpiry = _segment == 'Options' || _segment == 'Futures';

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
          child: Column(children: [
        // Search bar
        Container(
          color: t.sheet,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(
                child: Container(
              height: 46,
              decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.div)),
              child: Row(children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded, size: 18, color: t.t3),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: t.t1),
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'NIFTY, RELIANCE, HDFC…',
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: t.t3,
                          fontWeight: FontWeight.w400)),
                  onChanged: _search,
                )),
                if (_searching && _ctrl.text.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.8, color: _T.blue)))
                else if (_ctrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _ctrl.clear();
                      _search('');
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child:
                            Icon(Icons.close_rounded, size: 16, color: t.t3)),
                  ),
              ]),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(
                      fontSize: 14,
                      color: _T.blue,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),

        // Option chain CTA
        Container(
          color: t.sheet,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openOptionChain,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                    color: _T.ce.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: _T.ce.withOpacity(0.2))),
                child: Row(children: [
                  Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: _T.ce.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.table_chart_outlined,
                          size: 15, color: _T.ce)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Option Chain',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _T.ce)),
                        Text(
                            _ctrl.text.isNotEmpty
                                ? 'View CE & PE for ${_ctrl.text.toUpperCase()}'
                                : 'Browse all strikes side-by-side',
                            style: TextStyle(
                                fontSize: 11, color: _T.ce.withOpacity(0.6))),
                      ])),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: _T.ce),
                ]),
              ),
            ),
          ),
        ),

        // Segment chips
        Container(
          color: t.sheet,
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                height: 34,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _segments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final s = _segments[i];
                    final active = s == _segment;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _segment = s);
                        _search(_ctrl.text);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                            color: active ? _T.blue.withOpacity(0.1) : t.chip,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: active
                                    ? _T.blue.withOpacity(0.4)
                                    : Colors.transparent,
                                width: 1.5)),
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? _T.blue : t.t2)),
                      ),
                    );
                  },
                )),
            if (showFnoExpiry) ...[
              const SizedBox(height: 8),
              SizedBox(
                  height: 28,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._exchanges.map((e) {
                        final active = e == _exchange;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _exchange = active ? null : e);
                            _search(_ctrl.text);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: active ? t.chip : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color:
                                        active ? t.div : Colors.transparent)),
                            child: Text(e,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active ? t.t1 : t.t3)),
                          ),
                        );
                      }),
                      Container(
                          width: 1,
                          height: 18,
                          color: t.div,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5)),
                      ...[null, 'weekly', 'monthly'].map((ex) {
                        final active = ex == _expiry;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _expiry = active ? null : ex);
                            _search(_ctrl.text);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: active
                                    ? _T.amber.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: active
                                        ? _T.amber.withOpacity(0.4)
                                        : Colors.transparent)),
                            child: Text(ex ?? 'All exp.',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active ? _T.amber : t.t3)),
                          ),
                        );
                      }),
                    ],
                  )),
            ],
          ]),
        ),

        Divider(height: 1, color: t.div),

        Expanded(
          child: _searching && _results.isEmpty
              ? Center(
                  child:
                      CircularProgressIndicator(color: _T.blue, strokeWidth: 2))
              : _results.isEmpty
                  ? _buildEmptyState(t)
                  : _buildResultsList(t),
        ),
      ])),
    );
  }

  Widget _buildResultsList(_T t) {
    final isDefault = _ctrl.text.trim().isEmpty;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _results.length + (isDefault ? 1 : 0),
      separatorBuilder: (_, i) => (isDefault && i == 0)
          ? const SizedBox.shrink()
          : Divider(height: 1, color: t.divLight, indent: 16, endIndent: 16),
      itemBuilder: (_, i) {
        if (isDefault && i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
                _segment == 'All'
                    ? 'Popular Instruments'
                    : 'Trending in $_segment',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: t.t3,
                    letterSpacing: 0.4)),
          );
        }
        final doc = _results[isDefault ? i - 1 : i];
        return _SearchResultTile(
            t: t, doc: doc, onSelect: (d) => Navigator.pop(context, d));
      },
    );
  }

  Widget _buildEmptyState(_T t) {
    if (_ctrl.text.isNotEmpty && !_searching) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, size: 36, color: t.t3),
        const SizedBox(height: 12),
        Text('No results for "${_ctrl.text}"',
            style: TextStyle(fontSize: 14, color: t.t3)),
      ]));
    }
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.candlestick_chart_outlined, size: 40, color: t.t3),
      const SizedBox(height: 14),
      Text('No instruments found',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: t.t2)),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────
//  Search result tile  —  shows instrument_key as subtitle tag
// ─────────────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final _T t;
  final Map<String, dynamic> doc;
  final void Function(Map<String, dynamic>) onSelect;
  const _SearchResultTile(
      {required this.t, required this.doc, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final name = _sym(doc);
    final expiry = doc['expiry'] as String?;
    final strike = (doc['strike_price'] as num?)?.toDouble();
    final exch = (doc['exchange'] as String?) ?? '';
    final type = doc['type'] as String? ?? '';
    final label = _optLabel(doc);
    final color = _optColor(doc);
    final isOption = type == 'option';
    final isFuture = type == 'future';
    final instrKey = (doc['instrument_key'] as String?) ?? '';

    final subtitleParts = <String>[];
    if (isOption || isFuture) {
      if (expiry != null) subtitleParts.add('Exp $expiry');
      if (strike != null && strike > 0)
        subtitleParts.add('@ ${strike.toStringAsFixed(0)}');
    } else {
      final n = doc['name'] as String? ?? '';
      if (n.isNotEmpty) subtitleParts.add(n);
    }

    return GestureDetector(
      onTap: () => onSelect(doc),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  if (isOption || isFuture) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                      child: Text(name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: t.t1),
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  _Pill(label: exch, color: t.t3),
                ]),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitleParts.join('  ·  '),
                      style: TextStyle(fontSize: 11, color: t.t3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                if (instrKey.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(instrKey,
                      style: TextStyle(
                          fontSize: 10,
                          color: t.t3.withOpacity(0.6),
                          fontFamily: 'monospace'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ])),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  OPTION CHAIN PAGE
// ═══════════════════════════════════════════════════════════════

class _OptionChainPage extends StatefulWidget {
  final String? underlying;
  final meili.MeiliSearchClient meiliClient;
  final void Function(Map<String, dynamic>) onSelect;
  const _OptionChainPage(
      {this.underlying, required this.meiliClient, required this.onSelect});
  @override
  State<_OptionChainPage> createState() => _OptionChainPageState();
}

class _OptionChainPageState extends State<_OptionChainPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false, _suggestLoading = false;
  String? _selectedExpiry;
  List<String> _expiries = [];
  Map<double, Map<String, Map<String, dynamic>>> _chain = {};
  Map<String, Map<double, Map<String, Map<String, dynamic>>>> _allData = {};
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  DateTime _lastTyped = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.underlying != null) {
      _ctrl.text = widget.underlying!;
      _fetch(widget.underlying!);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final now = DateTime.now();
    _lastTyped = now;
    await Future.delayed(const Duration(milliseconds: 300));
    if (_lastTyped != now || !mounted) return;
    setState(() => _suggestLoading = true);
    try {
      final res = await widget.meiliClient.index('stocks_upstox').search(
          trimmed,
          meili.SearchQuery(
              filter: 'type = "option"',
              attributesToRetrieve: ['trading_symbol', 'underlying_symbol'],
              limit: 50));
      final hits = res.hits.cast<Map<String, dynamic>>();
      final seen = <String>{};
      final underlyings = <String>[];
      final prefixRe = RegExp(r'^([A-Z&]+)');
      for (final h in hits) {
        final us = (h['underlying_symbol'] as String?)?.toUpperCase();
        if (us != null && seen.add(us)) {
          underlyings.add(us);
          continue;
        }
        final sym = _sym(h).toUpperCase();
        final match = prefixRe.firstMatch(sym);
        if (match != null) {
          final prefix = match.group(1)!;
          if (seen.add(prefix)) underlyings.add(prefix);
        }
      }
      final ql = trimmed.toUpperCase();
      underlyings.sort((a, b) {
        if (a == ql && b != ql) return -1;
        if (b == ql && a != ql) return 1;
        if (a.startsWith(ql) && !b.startsWith(ql)) return -1;
        if (b.startsWith(ql) && !a.startsWith(ql)) return 1;
        return a.compareTo(b);
      });
      if (mounted)
        setState(() {
          _suggestions = underlyings.take(8).toList();
          _showSuggestions = underlyings.isNotEmpty;
          _suggestLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _suggestLoading = false);
    }
  }

  void _selectSuggestion(String u) {
    _ctrl.text = u;
    _focus.unfocus();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _fetch(u);
  }

  Future<void> _fetch(String underlying) async {
    if (underlying.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _chain = {};
      _expiries = [];
      _selectedExpiry = null;
      _allData = {};
      _showSuggestions = false;
      _suggestions = [];
    });
    try {
      final res = await widget.meiliClient.index('stocks_upstox').search(
          underlying.trim(),
          meili.SearchQuery(
            filter: 'type = "option"',
            attributesToRetrieve: [
              'id',
              'trading_symbol',
              'name',
              'exchange',
              'type',
              'option_type',
              'expiry',
              'expiry_ts',
              'strike_price',
              'lot_size',
              'instrument_key',
              'underlying_symbol'
            ],
            limit: 500,
          ));
      final hits = res.hits.cast<Map<String, dynamic>>();
      final ql = underlying.trim().toUpperCase();
      final filtered = hits.where((h) {
        final us = (h['underlying_symbol'] as String?)?.toUpperCase();
        if (us == ql) return true;
        final sym = _sym(h).toUpperCase();
        final match = RegExp(r'^([A-Z&]+)').firstMatch(sym);
        return match != null && match.group(1) == ql;
      }).toList();

      final Map<String, Map<double, Map<String, Map<String, dynamic>>>> byExp =
          {};
      for (final h in filtered.isNotEmpty ? filtered : hits) {
        final optType = h['option_type'] as String?;
        final strike = (h['strike_price'] as num?)?.toDouble();
        final exp = h['expiry'] as String?;
        if (optType == null || strike == null || exp == null) continue;
        byExp[exp] ??= {};
        byExp[exp]![strike] ??= {};
        byExp[exp]![strike]![optType] = h;
      }

      final expiries = byExp.keys.toList()..sort();
      final sel = expiries.isNotEmpty ? expiries.first : null;
      if (mounted)
        setState(() {
          _allData = byExp;
          _expiries = expiries;
          _selectedExpiry = sel;
          _chain = sel != null ? (byExp[sel] ?? {}) : {};
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = _T(isDark);
    final strikes = _chain.keys.toList()..sort();

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
          child: Column(children: [
        Container(
          color: t.sheet,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: t.chip, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 13, color: t.t2))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Option Chain',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: t.t1,
                          letterSpacing: -0.3)),
                  Text(
                      _ctrl.text.isNotEmpty
                          ? _ctrl.text.toUpperCase()
                          : 'Select underlying',
                      style: TextStyle(fontSize: 11, color: t.t3)),
                ])),
          ]),
        ),
        Container(
          color: t.sheet,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: Container(
                height: 42,
                decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                        color:
                            _showSuggestions ? _T.ce.withOpacity(0.35) : t.div,
                        width: _showSuggestions ? 1.5 : 1)),
                child: Row(children: [
                  const SizedBox(width: 12),
                  if (_suggestLoading)
                    SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.6, color: _T.ce))
                  else
                    Icon(Icons.search_rounded, size: 15, color: t.t3),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: t.t1),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'e.g. NIFTY, BANKNIFTY, RELIANCE',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: t.t3,
                            fontWeight: FontWeight.w400)),
                    onChanged: _onChanged,
                    onSubmitted: (v) =>
                        _selectSuggestion(v.trim().toUpperCase()),
                    textInputAction: TextInputAction.search,
                  )),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          setState(() {
                            _suggestions = [];
                            _showSuggestions = false;
                          });
                        },
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(Icons.close_rounded,
                                size: 14, color: t.t3))),
                ]),
              ))
            ]),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: _showSuggestions
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                          color: t.card,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: t.div)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 9, 12, 6),
                                child: Text('Underlyings',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: t.t3,
                                        letterSpacing: 0.4))),
                            ..._suggestions.asMap().entries.map((e) {
                              final isLast = e.key == _suggestions.length - 1;
                              return GestureDetector(
                                onTap: () => _selectSuggestion(e.value),
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: isLast
                                          ? null
                                          : Border(
                                              bottom: BorderSide(
                                                  color: t.divLight))),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 11),
                                  child: Row(children: [
                                    Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                            color: _T.ce.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(7)),
                                        child: const Icon(
                                            Icons.table_chart_outlined,
                                            size: 13,
                                            color: _T.ce)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(e.value,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: t.t1))),
                                    Text('Options',
                                        style: TextStyle(
                                            fontSize: 10, color: t.t3)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios_rounded,
                                        size: 10, color: t.t3),
                                  ]),
                                ),
                              );
                            }),
                          ]),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_expiries.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _expiries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final e = _expiries[i];
                      final active = e == _selectedExpiry;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedExpiry = e;
                          _chain = _allData[e] ?? {};
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: active ? _T.ce.withOpacity(0.12) : t.chip,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: active
                                      ? _T.ce.withOpacity(0.4)
                                      : Colors.transparent,
                                  width: 1.5)),
                          child: Text(e,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: active ? _T.ce : t.t2)),
                        ),
                      );
                    },
                  )),
            ],
          ]),
        ),
        Divider(height: 1, color: t.div),
        Container(
          color: t.sheet,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(children: [
                      Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                              color: _T.ce, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      const Text('CE  Call',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _T.ce)),
                    ]))),
            Container(
                width: 76,
                child: Center(
                    child: Text('Strike',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: t.t2)))),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('PE  Put',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _T.pe)),
                          const SizedBox(width: 5),
                          Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: _T.pe, shape: BoxShape.circle)),
                        ]))),
          ]),
        ),
        Divider(height: 1, color: t.div),
        Expanded(
            child: _loading
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: _T.ce, strokeWidth: 2),
                    const SizedBox(height: 14),
                    Text('Loading option chain…',
                        style: TextStyle(fontSize: 13, color: t.t3)),
                  ]))
                : strikes.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.table_chart_outlined, size: 44, color: t.t3),
                        const SizedBox(height: 14),
                        Text(
                            _ctrl.text.isEmpty
                                ? 'Enter a symbol to load chain'
                                : 'No options found',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: t.t2)),
                        const SizedBox(height: 6),
                        Text('Try: NIFTY, BANKNIFTY, RELIANCE',
                            style: TextStyle(fontSize: 12, color: t.t3)),
                      ]))
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: strikes.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: t.divLight),
                        itemBuilder: (_, i) => _ChainRow(
                          t: t,
                          strike: strikes[i],
                          ceDoc: _chain[strikes[i]]?['CE'],
                          peDoc: _chain[strikes[i]]?['PE'],
                          onSelect: widget.onSelect,
                        ),
                      )),
      ])),
    );
  }
}

class _ChainRow extends StatelessWidget {
  final _T t;
  final double strike;
  final Map<String, dynamic>? ceDoc, peDoc;
  final void Function(Map<String, dynamic>) onSelect;
  const _ChainRow(
      {required this.t,
      required this.strike,
      this.ceDoc,
      this.peDoc,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final strikeStr =
        strike % 1 == 0 ? strike.toInt().toString() : strike.toStringAsFixed(1);
    return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: ceDoc != null
                    ? () {
                        HapticFeedback.selectionClick();
                        onSelect(ceDoc!);
                      }
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: ceDoc != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Text(_sym(ceDoc!),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _T.ce),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Row(children: [
                                Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                        color: _T.ce, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text('Select CE',
                                    style: TextStyle(fontSize: 9, color: t.t3))
                              ]),
                            ])
                      : Center(
                          child: Text('—',
                              style: TextStyle(fontSize: 12, color: t.t3))),
                ),
              ))),
      Container(
          width: 76,
          decoration: BoxDecoration(
              color: t.chip,
              border: Border.symmetric(vertical: BorderSide(color: t.div))),
          alignment: Alignment.center,
          child: Text(strikeStr,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: t.t1))),
      Expanded(
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: peDoc != null
                    ? () {
                        HapticFeedback.selectionClick();
                        onSelect(peDoc!);
                      }
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: peDoc != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Text(_sym(peDoc!),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _T.pe),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right),
                              const SizedBox(height: 2),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Select PE',
                                        style: TextStyle(
                                            fontSize: 9, color: t.t3)),
                                    const SizedBox(width: 4),
                                    Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                            color: _T.pe,
                                            shape: BoxShape.circle))
                                  ]),
                            ])
                      : Center(
                          child: Text('—',
                              style: TextStyle(fontSize: 12, color: t.t3))),
                ),
              ))),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════
//  FIELD WIDGETS
// ═══════════════════════════════════════════════════════════════

class _QtyField extends StatefulWidget {
  final _T t;
  final Color ac;
  final TextEditingController ctrl;
  final VoidCallback? onChanged;
  const _QtyField(
      {required this.t, required this.ac, required this.ctrl, this.onChanged});
  @override
  State<_QtyField> createState() => _QtyFieldState();
}

class _QtyFieldState extends State<_QtyField> {
  void _change(int d) {
    final v = (int.tryParse(widget.ctrl.text) ?? 1) + d;
    widget.ctrl.text = v.clamp(1, 100000).toString();
    setState(() {});
    widget.onChanged?.call();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Qty',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.t3,
              letterSpacing: 0.4)),
      const SizedBox(height: 8),
      Container(
        height: 54,
        decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: t.div)),
        child: Row(children: [
          GestureDetector(
              onTap: () => _change(-1),
              child: Container(
                  width: 46,
                  height: double.infinity,
                  decoration: BoxDecoration(
                      color: t.chip,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12))),
                  child: Icon(Icons.remove_rounded, size: 18, color: t.t2))),
          Expanded(
              child: TextFormField(
            controller: widget.ctrl,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: t.t1,
                letterSpacing: -0.5),
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              setState(() {});
              widget.onChanged?.call();
            },
            validator: (v) =>
                (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null,
          )),
          GestureDetector(
              onTap: () => _change(1),
              child: Container(
                  width: 46,
                  height: double.infinity,
                  decoration: BoxDecoration(
                      color: widget.ac.withOpacity(0.12),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(12))),
                  child: Icon(Icons.add_rounded, size: 18, color: widget.ac))),
        ]),
      ),
    ]);
  }
}

class _PriceField extends StatelessWidget {
  final _T t;
  final Color ac;
  final TextEditingController ctrl;
  final bool needsPrice;
  final String orderType;
  const _PriceField(
      {required this.t,
      required this.ac,
      required this.ctrl,
      required this.needsPrice,
      required this.orderType});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Price',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.t3,
              letterSpacing: 0.4)),
      const SizedBox(height: 8),
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
                color: needsPrice ? ac.withOpacity(0.4) : t.div,
                width: needsPrice ? 1.5 : 1)),
        child: needsPrice
            ? Row(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('₹',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: ac))),
                Expanded(
                    child: TextFormField(
                  controller: ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: t.t1),
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '0.00',
                      hintStyle:
                          TextStyle(color: t.t3, fontWeight: FontWeight.w500)),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  ],
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null,
                )),
              ])
            : Center(
                child: Text('Market',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.t3))),
      ),
    ]);
  }
}

class _TriggerField extends StatelessWidget {
  final _T t;
  final TextEditingController ctrl;
  const _TriggerField({required this.t, required this.ctrl});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Trigger price',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.t3,
              letterSpacing: 0.4)),
      const SizedBox(height: 8),
      Container(
        height: 54,
        decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _T.amber.withOpacity(0.4), width: 1.5)),
        child: Row(children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.notifications_active_rounded,
                  size: 16, color: _T.amber)),
          Expanded(
              child: TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: t.t1),
            decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: '0.00',
                hintStyle: TextStyle(color: t.t3, fontWeight: FontWeight.w500)),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            validator: (v) =>
                (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Required' : null,
          )),
        ]),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
//  SUCCESS DIALOG
// ═══════════════════════════════════════════════════════════════

class _SuccessDialog extends StatelessWidget {
  final String orderId, mode, symbol;
  final Color activeColor;
  final VoidCallback onDone;
  const _SuccessDialog(
      {required this.orderId,
      required this.mode,
      required this.symbol,
      required this.activeColor,
      required this.onDone});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF13161F) : Colors.white;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(26),
            border:
                Border.all(color: activeColor.withOpacity(0.3), width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: activeColor, size: 30)),
          const SizedBox(height: 18),
          Text('Order Placed!',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('$mode · $symbol',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: activeColor)),
          if (orderId.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Order ID: ',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45)),
                Text(orderId,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: 'monospace')),
              ]),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13))),
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)))),
        ]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      );
}
