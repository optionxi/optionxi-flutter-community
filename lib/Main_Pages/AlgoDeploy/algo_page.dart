import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meilisearch/meilisearch.dart' as meili;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/Components/cust_bottom_sheet_beta_alert.dart';
import 'package:optionxi/Components/cust_contact_us.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
//
//  Light mode palette:
//    Background  #F7F7F8   (off-white, not pure white)
//    Surface     #FFFFFF
//    Border      #E4E4E7
//    Text-1      #18181B   (primary text)
//    Text-2      #71717A   (muted)
//    Accent      #2563EB   (single blue – used sparingly)
//    Green       #16A34A
//    Red         #DC2626
//
//  Dark mode palette:
//    Background  #0F0F11
//    Surface     #18181B
//    Border      #27272A
//    Text-1      #FAFAFA
//    Text-2      #71717A
//    Accent      #3B82F6
//    Green       #22C55E
//    Red         #EF4444

class _C {
  // Accent
  static const accent = Color(0xFF2563EB);
  static const accentDark = Color(0xFF3B82F6);

  // Semantic
  static const green = Color(0xFF16A34A);
  static const greenDark = Color(0xFF22C55E);
  static const red = Color(0xFFDC2626);
  static const redDark = Color(0xFFEF4444);
  static const amber = Color(0xFFD97706);

  // Neutral light
  static const bg = Color(0xFFF7F7F8);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E4E7);
  static const text1 = Color(0xFF18181B);
  static const text2 = Color(0xFF71717A);
  static const chip = Color(0xFFF4F4F5);

  // Neutral dark
  static const bgDark = Color(0xFF0F0F11);
  static const surfaceDark = Color(0xFF18181B);
  static const borderDark = Color(0xFF27272A);
  static const text1Dark = Color(0xFFFAFAFA);
  static const text2Dark = Color(0xFF71717A);
  static const chipDark = Color(0xFF27272A);
}

// ── ThemeController stub ──────────────────────────────────────────────────────
class ThemeController {
  static final ThemeController instance = ThemeController._();
  ThemeController._();
  bool get isDarkMode =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;
}

// ══════════════════════════════════════════════════════════════════════════════
//  ENUMS
// ══════════════════════════════════════════════════════════════════════════════

enum AlgoTier { free, basic, premium }

enum AlgoCategory { breakout, momentum, reversal, volatility, custom }

enum ExecutionMode { autoExecute, verifyFirst }

// ══════════════════════════════════════════════════════════════════════════════
//  MODELS  (unchanged)
// ══════════════════════════════════════════════════════════════════════════════

class AlgoField {
  final String key;
  final String label;
  final String hint;
  final TextInputType inputType;
  final bool required;

  const AlgoField({
    required this.key,
    required this.label,
    required this.hint,
    this.inputType = TextInputType.number,
    this.required = true,
  });

  factory AlgoField.fromMap(Map<dynamic, dynamic> m) => AlgoField(
        key: m['key'] ?? '',
        label: m['label'] ?? '',
        hint: m['hint'] ?? '',
        inputType: m['inputType'] == 'text'
            ? TextInputType.text
            : TextInputType.number,
        required: m['required'] != false,
      );
}

class AlgoTemplate {
  final String id;
  final String name;
  final String description;
  final AlgoTier tier;
  final AlgoCategory category;
  final IconData icon;
  final Color accentColor;
  final List<AlgoField> fields;
  final int order;

  const AlgoTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.category,
    required this.icon,
    required this.accentColor,
    required this.fields,
    required this.order,
  });

  factory AlgoTemplate.fromMap(Map<dynamic, dynamic> m) {
    final tierStr = m['tier'] ?? 'free';
    final catStr = m['category'] ?? 'breakout';
    final tier = {
          'free': AlgoTier.free,
          'basic': AlgoTier.basic,
          'premium': AlgoTier.premium,
        }[tierStr] ??
        AlgoTier.free;
    final category = {
          'breakout': AlgoCategory.breakout,
          'momentum': AlgoCategory.momentum,
          'reversal': AlgoCategory.reversal,
          'volatility': AlgoCategory.volatility,
          'custom': AlgoCategory.custom,
        }[catStr] ??
        AlgoCategory.breakout;

    final List<AlgoField> fields = [];
    if (m['fields'] != null) {
      final rawFields = m['fields'];
      if (rawFields is List) {
        for (final f in rawFields) {
          if (f != null)
            fields.add(AlgoField.fromMap(Map<dynamic, dynamic>.from(f)));
        }
      } else if (rawFields is Map) {
        final sorted = rawFields.entries.toList()
          ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
        for (final e in sorted) {
          if (e.value != null)
            fields.add(AlgoField.fromMap(Map<dynamic, dynamic>.from(e.value)));
        }
      }
    }

    return AlgoTemplate(
      id: m['id'] ?? '',
      name: m['name'] ?? 'Unnamed',
      description: m['description'] ?? '',
      tier: tier,
      category: category,
      icon: _iconFromString(m['icon'] ?? ''),
      accentColor: _colorFromHex(m['accentColor'] ?? '2563EB'),
      fields: fields,
      order: (m['order'] ?? 0) as int,
    );
  }

  static IconData _iconFromString(String key) {
    const map = <String, IconData>{
      'trending_up': Icons.trending_up_rounded,
      'price_check': Icons.price_check_rounded,
      'rocket_launch': Icons.rocket_launch_rounded,
      'alarm': Icons.alarm_rounded,
      'show_chart': Icons.show_chart_rounded,
      'refresh': Icons.refresh_rounded,
      'auto_awesome': Icons.auto_awesome_rounded,
      'moving': Icons.moving_rounded,
      'bolt': Icons.bolt_rounded,
      'bar_chart': Icons.bar_chart_rounded,
      'candlestick': Icons.candlestick_chart_rounded,
      'waterfall': Icons.waterfall_chart_rounded,
      'analytics': Icons.analytics_rounded,
      'timeline': Icons.timeline_rounded,
    };
    return map[key] ?? Icons.auto_graph_rounded;
  }

  static Color _colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) return _C.accent;
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class UserAlgo {
  final String id;
  final String templateId;
  final String name;
  final String broker;
  final bool isActive;
  final bool isPending;
  final Map<String, dynamic> config;
  final List<String> stockPool;
  final bool aiChoosesStocks;
  final int capitalAmount;
  final int aiMaxPicks;
  final ExecutionMode executionMode;
  final DateTime createdAt;

  const UserAlgo({
    required this.id,
    required this.templateId,
    required this.name,
    required this.broker,
    required this.isActive,
    this.isPending = false,
    required this.config,
    this.stockPool = const [],
    this.aiChoosesStocks = false,
    this.capitalAmount = 20000,
    this.aiMaxPicks = 2,
    this.executionMode = ExecutionMode.verifyFirst,
    required this.createdAt,
  });

  factory UserAlgo.fromMap(String id, Map<dynamic, dynamic> m) {
    final rawPool = m['stockPool'];
    List<String> pool = [];
    if (rawPool is List) {
      pool = rawPool.map((e) => e.toString()).toList();
    } else if (rawPool is Map) {
      pool = rawPool.values.map((e) => e.toString()).toList();
    }
    final execStr = m['executionMode'] ?? 'verifyFirst';
    return UserAlgo(
      id: id,
      templateId: m['templateId'] ?? '',
      name: m['name'] ?? 'My Algo',
      broker: m['broker'] ?? 'unknown',
      isActive: m['isActive'] == true,
      isPending: m['isPending'] == true,
      config: Map<String, dynamic>.from(m['config'] ?? {}),
      stockPool: pool,
      aiChoosesStocks: m['aiChoosesStocks'] == true,
      capitalAmount: (m['capitalAmount'] ?? 20000) as int,
      aiMaxPicks: (m['aiMaxPicks'] ?? 2) as int,
      executionMode: execStr == 'autoExecute'
          ? ExecutionMode.autoExecute
          : ExecutionMode.verifyFirst,
      createdAt: m['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'templateId': templateId,
        'name': name,
        'broker': broker,
        'isActive': isActive,
        'isPending': isPending,
        'config': config,
        'stockPool': stockPool,
        'aiChoosesStocks': aiChoosesStocks,
        'capitalAmount': capitalAmount,
        'aiMaxPicks': aiMaxPicks,
        'executionMode': executionMode == ExecutionMode.autoExecute
            ? 'autoExecute'
            : 'verifyFirst',
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

class AlgoTradeHistory {
  final String id;
  final String algoId;
  final String algoName;
  final String templateId;
  final List<TradeEvent> events;
  final List<String> triggeredStocks;
  final int pnl;
  final String remark;
  final DateTime date;

  const AlgoTradeHistory({
    required this.id,
    required this.algoId,
    required this.algoName,
    required this.templateId,
    required this.events,
    required this.triggeredStocks,
    required this.pnl,
    required this.remark,
    required this.date,
  });

  factory AlgoTradeHistory.fromMap(String id, Map<dynamic, dynamic> m) {
    final rawEvents = m['events'] ?? {};
    List<TradeEvent> events = [];
    if (rawEvents is Map) {
      rawEvents.forEach((k, v) {
        try {
          events.add(TradeEvent.fromMap(Map<dynamic, dynamic>.from(v)));
        } catch (_) {}
      });
    }
    events.sort((a, b) => a.time.compareTo(b.time));
    final rawStocks = m['triggeredStocks'];
    List<String> stocks = [];
    if (rawStocks is List) {
      stocks = rawStocks.map((e) => e.toString()).toList();
    }
    return AlgoTradeHistory(
      id: id,
      algoId: m['algoId'] ?? '',
      algoName: m['algoName'] ?? '',
      templateId: m['templateId'] ?? '',
      events: events,
      triggeredStocks: stocks,
      pnl: (m['pnl'] ?? 0) as int,
      remark: m['remark'] ?? '',
      date: m['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['date'])
          : DateTime.now(),
    );
  }
}

class TradeEvent {
  final String type;
  final String stock;
  final DateTime time;
  final double price;
  final int qty;

  const TradeEvent({
    required this.type,
    required this.stock,
    required this.time,
    required this.price,
    required this.qty,
  });

  factory TradeEvent.fromMap(Map<dynamic, dynamic> m) => TradeEvent(
        type: m['type'] ?? 'buy',
        stock: m['stock'] ?? '',
        time: m['time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['time'])
            : DateTime.now(),
        price: (m['price'] ?? 0).toDouble(),
        qty: (m['qty'] ?? 0) as int,
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  SHIMMER
// ══════════════════════════════════════════════════════════════════════════════

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _Shimmer({required this.width, required this.height, this.radius = 6});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
    final hl = isDark ? const Color(0xFF3F3F46) : const Color(0xFFF4F4F5);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            colors: [base, hl, base],
            stops: [
              (_anim.value - 0.5).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.5).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlgoCardSkeleton extends StatelessWidget {
  const _AlgoCardSkeleton();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _C.surfaceDark : _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? _C.borderDark : _C.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Shimmer(width: 36, height: 36, radius: 8),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Shimmer(width: 130, height: 13, radius: 4),
            const SizedBox(height: 6),
            _Shimmer(width: 60, height: 11, radius: 4),
          ]),
          const Spacer(),
          _Shimmer(width: 70, height: 28, radius: 6),
        ]),
        const SizedBox(height: 12),
        _Shimmer(width: double.infinity, height: 11, radius: 4),
        const SizedBox(height: 5),
        _Shimmer(width: 180, height: 11, radius: 4),
        const SizedBox(height: 12),
        Row(children: [
          _Shimmer(width: 60, height: 22, radius: 4),
          const SizedBox(width: 6),
          _Shimmer(width: 60, height: 22, radius: 4),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN PAGE
// ══════════════════════════════════════════════════════════════════════════════

class AlgoTradingPage extends StatefulWidget {
  const AlgoTradingPage({Key? key}) : super(key: key);
  @override
  State<AlgoTradingPage> createState() => _AlgoTradingPageState();
}

class _AlgoTradingPageState extends State<AlgoTradingPage>
    with SingleTickerProviderStateMixin {
  final themeController = ThemeController.instance;

  String? _uid;
  bool _isSubscribed = false;
  List<String> _connectedBrokers = [];
  List<AlgoTemplate> _templates = [];
  bool _templatesLoading = true;
  String? _templatesError;
  List<UserAlgo> _userAlgos = [];
  bool _userAlgosLoading = true;
  StreamSubscription<DatabaseEvent>? _algoSub;
  List<AlgoTradeHistory> _history = [];
  bool _historyLoading = true;
  StreamSubscription<DatabaseEvent>? _historySub;

  AlgoTier? _selectedTier;
  AlgoCategory? _selectedCategory;

  late TabController _tabController;

  static const _brokers = ['zerodha', 'fyers', 'upstox'];
  static const int _freeAlgoLimit = 2;
  static const int _premiumAlgoLimit = 15;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBetaBottomSheet(context);
    });
  }

  @override
  void dispose() {
    _algoSub?.cancel();
    _historySub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _uid = user.uid;
    final db = FirebaseDatabase.instance;

    final subSnap = await db.ref('subscriptions/$_uid/subscribed').get();
    if (mounted) setState(() => _isSubscribed = subSnap.value == true);

    final detected = <String>[];
    for (final broker in _brokers) {
      final snap = await db.ref('brokers/$broker/$_uid/status').get();
      if (snap.value == 'authenticated') detected.add(broker);
    }
    if (mounted) setState(() => _connectedBrokers = detected);

    _fetchTemplates();

    _algoSub = db.ref('user_algos/$_uid').onValue.listen((event) {
      if (!mounted) return;
      final algos = <UserAlgo>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final raw = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        raw.forEach((k, v) {
          try {
            algos.add(
                UserAlgo.fromMap(k.toString(), Map<dynamic, dynamic>.from(v)));
          } catch (_) {}
        });
        algos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      setState(() {
        _userAlgos = algos;
        _userAlgosLoading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _userAlgosLoading = false);
    });

    _historySub = db.ref('algo_history/$_uid').onValue.listen((event) {
      if (!mounted) return;
      final list = <AlgoTradeHistory>[];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final raw = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        raw.forEach((k, v) {
          try {
            list.add(AlgoTradeHistory.fromMap(
                k.toString(), Map<dynamic, dynamic>.from(v)));
          } catch (_) {}
        });
        list.sort((a, b) => b.date.compareTo(a.date));
      }
      setState(() {
        _history = list;
        _historyLoading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _historyLoading = false);
    });
  }

  Future<void> _fetchTemplates() async {
    if (mounted)
      setState(() {
        _templatesLoading = true;
        _templatesError = null;
      });
    try {
      final snap = await FirebaseDatabase.instance.ref('algo_templates').get();
      if (!snap.exists || snap.value == null) {
        if (mounted)
          setState(() {
            _templates = [];
            _templatesLoading = false;
            _templatesError = 'No templates found.';
          });
        return;
      }
      final raw = Map<dynamic, dynamic>.from(snap.value as Map);
      final parsed = <AlgoTemplate>[];
      for (final entry in raw.entries) {
        try {
          parsed.add(
              AlgoTemplate.fromMap(Map<dynamic, dynamic>.from(entry.value)));
        } catch (_) {}
      }
      parsed.sort((a, b) => a.order.compareTo(b.order));
      if (mounted)
        setState(() {
          _templates = parsed;
          _templatesLoading = false;
          _templatesError = null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _templatesLoading = false;
          _templatesError = 'Failed to load: ${e.toString()}';
        });
    }
  }

  int get _algoLimit => _isSubscribed ? _premiumAlgoLimit : _freeAlgoLimit;

  bool _canDeploy(AlgoTemplate tmpl) {
    if (tmpl.tier == AlgoTier.premium && !_isSubscribed) return false;
    return _userAlgos.length < _algoLimit;
  }

  AlgoTemplate? _templateForAlgo(UserAlgo algo) =>
      _templates.where((t) => t.id == algo.templateId).firstOrNull;

  Future<void> _toggleAlgo(UserAlgo algo) async {
    await FirebaseDatabase.instance
        .ref('user_algos/$_uid/${algo.id}')
        .update({'isPending': true, 'isActive': !algo.isActive});
  }

  Future<void> _deleteAlgo(UserAlgo algo) async {
    await FirebaseDatabase.instance.ref('user_algos/$_uid/${algo.id}').remove();
  }

  Future<void> _saveAlgo({
    required AlgoTemplate template,
    required String name,
    required String broker,
    required List<String> stockPool,
    required bool aiChoosesStocks,
    required int capitalAmount,
    required int aiMaxPicks,
    required ExecutionMode executionMode,
  }) async {
    final ref = FirebaseDatabase.instance.ref('user_algos/$_uid').push();
    await ref.set(UserAlgo(
      id: ref.key!,
      templateId: template.id,
      name: name,
      broker: broker,
      isActive: false,
      isPending: true,
      config: {},
      stockPool: stockPool,
      aiChoosesStocks: aiChoosesStocks,
      capitalAmount: capitalAmount,
      aiMaxPicks: aiMaxPicks,
      executionMode: executionMode,
      createdAt: DateTime.now(),
    ).toMap());
  }

  void _openBrokerConnectDialog() {
    showDialog(
      context: context,
      builder: (_) => _BrokerConnectDialog(connectedBrokers: _connectedBrokers),
    );
  }

  void _openDeploySheet(AlgoTemplate template) {
    if (_connectedBrokers.isEmpty) {
      _openBrokerConnectDialog();
      return;
    }
    if (!_canDeploy(template)) {
      if (template.tier == AlgoTier.premium) {
        _openPremiumDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Algo limit reached. Upgrade for more.')));
      }
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _DeployBottomSheet(
        template: template,
        connectedBrokers: _connectedBrokers,
        isSubscribed: _isSubscribed,
        onDeploy: ({
          required String name,
          required String broker,
          required List<String> stockPool,
          required bool aiChoosesStocks,
          required int capitalAmount,
          required int aiMaxPicks,
          required ExecutionMode executionMode,
        }) async {
          await _saveAlgo(
            template: template,
            name: name,
            broker: broker,
            stockPool: stockPool,
            aiChoosesStocks: aiChoosesStocks,
            capitalAmount: capitalAmount,
            aiMaxPicks: aiMaxPicks,
            executionMode: executionMode,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$name queued for deployment'),
              backgroundColor: _C.green,
            ));
          }
        },
      ),
    );
  }

  void _openEditSheet(UserAlgo algo) {
    final template = _templateForAlgo(algo);
    if (template == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _DeployBottomSheet(
        template: template,
        connectedBrokers: _connectedBrokers,
        existingAlgo: algo,
        isSubscribed: _isSubscribed,
        onDeploy: ({
          required String name,
          required String broker,
          required List<String> stockPool,
          required bool aiChoosesStocks,
          required int capitalAmount,
          required int aiMaxPicks,
          required ExecutionMode executionMode,
        }) async {
          await FirebaseDatabase.instance
              .ref('user_algos/$_uid/${algo.id}')
              .update({
            'name': name,
            'broker': broker,
            'stockPool': stockPool,
            'aiChoosesStocks': aiChoosesStocks,
            'capitalAmount': capitalAmount,
            'aiMaxPicks': aiMaxPicks,
            'executionMode': executionMode == ExecutionMode.autoExecute
                ? 'autoExecute'
                : 'verifyFirst',
            'isPending': true,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changes saved — syncing...')));
          }
        },
      ),
    );
  }

  void _openPremiumDialog() {
    showDialog(context: context, builder: (_) => _PremiumDialog(uid: _uid));
  }

  void _openCustomAlgoRequest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _CustomAlgoRequestSheet(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_uid == null) {
      return Scaffold(
        appBar: _buildAppBar(theme, isDark),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.no_accounts_rounded,
                size: 48, color: isDark ? _C.text2Dark : _C.text2),
            const SizedBox(height: 14),
            Text('Sign in to use Algo Trading',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? _C.text1Dark : _C.text1)),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? _C.bgDark : _C.bg,
      appBar: _buildAppBar(theme, isDark),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildHeroHeader(isDark),
        _buildTabBar(isDark),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMarketplaceTab(isDark),
              _buildMyAlgosTab(isDark),
              _buildHistoryTab(isDark),
            ],
          ),
        ),
      ]),
    );
  }

  AppBar _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: isDark ? _C.text1Dark : _C.text1),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text('Algo Trading',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? _C.text1Dark : _C.text1)),
      centerTitle: true,
      backgroundColor: isDark ? _C.surfaceDark : _C.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
            height: 1, thickness: 1, color: isDark ? _C.borderDark : _C.border),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.workspace_premium_rounded,
              size: 20,
              color: _isSubscribed
                  ? _C.amber
                  : (isDark ? _C.text2Dark : _C.text2)),
          onPressed: _openPremiumDialog,
          tooltip: 'Plans',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildHeroHeader(bool isDark) {
    final bg = isDark ? _C.surfaceDark : _C.surface;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final accent = isDark ? _C.accentDark : _C.accent;

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Broker row
        Row(children: [
          // Plan badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _isSubscribed
                  ? _C.amber.withOpacity(0.1)
                  : (isDark ? _C.chipDark : _C.chip),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _isSubscribed
                    ? _C.amber.withOpacity(0.3)
                    : (isDark ? _C.borderDark : _C.border),
              ),
            ),
            child: Text(
              _isSubscribed ? 'PREMIUM' : 'FREE PLAN',
              style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _isSubscribed ? _C.amber : text2,
                  letterSpacing: 0.8),
            ),
          ),
          const SizedBox(width: 8),
          // Connected brokers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ..._connectedBrokers.map((b) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: _openBrokerConnectDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _C.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: _C.green.withOpacity(0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle, color: _C.green)),
                            const SizedBox(width: 4),
                            Text(b.toUpperCase(),
                                style: GoogleFonts.robotoMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _C.green)),
                          ]),
                        ),
                      ),
                    )),
                GestureDetector(
                  onTap: _openBrokerConnectDialog,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: isDark ? _C.borderDark : _C.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, size: 11, color: accent),
                      const SizedBox(width: 2),
                      Text('Add broker',
                          style: GoogleFonts.robotoMono(
                              fontSize: 9,
                              color: accent,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        // Capacity row
        Row(children: [
          Text('${_userAlgos.length}/$_algoLimit algos active',
              style: GoogleFonts.inter(
                  fontSize: 12, color: text2, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (!_isSubscribed)
            GestureDetector(
              onTap: _openPremiumDialog,
              child: Text('Upgrade plan',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w500)),
            ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (_userAlgos.length / _algoLimit).clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: isDark ? _C.borderDark : _C.border,
            valueColor: AlwaysStoppedAnimation(
                _userAlgos.length >= _algoLimit ? _C.red : accent),
          ),
        ),
      ]),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final bg = isDark ? _C.surfaceDark : _C.surface;
    final accent = isDark ? _C.accentDark : _C.accent;
    final text2 = isDark ? _C.text2Dark : _C.text2;

    return Container(
      color: bg,
      child: Column(children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Marketplace'),
            Tab(text: 'My Algos'),
            Tab(text: 'History'),
          ],
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
          labelColor: accent,
          unselectedLabelColor: text2,
          indicatorColor: accent,
          indicatorWeight: 2,
          dividerColor: isDark ? _C.borderDark : _C.border,
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MARKETPLACE TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMarketplaceTab(bool isDark) {
    if (_templatesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: isDark ? _C.text2Dark : _C.text2),
            const SizedBox(height: 16),
            Text('Could not load strategies',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? _C.text1Dark : _C.text1)),
            const SizedBox(height: 6),
            Text(_templatesError!,
                style: GoogleFonts.inter(
                    color: isDark ? _C.text2Dark : _C.text2, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _PrimaryButton(
                label: 'Retry', onTap: _fetchTemplates, isDark: isDark),
          ]),
        ),
      );
    }

    if (_templatesLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: 4,
        itemBuilder: (_, __) => const _AlgoCardSkeleton(),
      );
    }

    if (_templates.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: isDark ? _C.text2Dark : _C.text2),
          const SizedBox(height: 14),
          Text('No strategies available',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? _C.text1Dark : _C.text1)),
        ]),
      );
    }

    final filtered = _templates.where((t) {
      if (_selectedTier != null && t.tier != _selectedTier) return false;
      if (_selectedCategory != null && t.category != _selectedCategory)
        return false;
      return true;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildPricingBanner(isDark)),
        SliverToBoxAdapter(child: _buildFilterRow(isDark)),
        if (filtered.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text('No strategies match this filter.',
                  style: GoogleFonts.inter(
                      color: isDark ? _C.text2Dark : _C.text2, fontSize: 13)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _AlgoCard(
                  template: filtered[i],
                  canDeploy: _canDeploy(filtered[i]),
                  isSubscribed: _isSubscribed,
                  onDeploy: () => _openDeploySheet(filtered[i]),
                  onPremium: _openPremiumDialog,
                  isDark: isDark,
                ),
                childCount: filtered.length,
              ),
            ),
          ),
        SliverToBoxAdapter(child: _buildCustomAlgoCard(isDark)),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildPricingBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Expanded(
            child: _TierBadge(
                label: 'Free',
                sublabel: '2 algos',
                color: _C.green,
                isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(
            child: _TierBadge(
                label: 'Basic',
                sublabel: 'GTT · Free',
                color: isDark ? _C.accentDark : _C.accent,
                isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _openPremiumDialog,
            child: _TierBadge(
                label: '₹399/mo',
                sublabel: '15 algos',
                color: _C.amber,
                isDark: isDark),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        _Chip(
          label: 'All',
          selected: _selectedTier == null && _selectedCategory == null,
          onTap: () => setState(() {
            _selectedTier = null;
            _selectedCategory = null;
          }),
          isDark: isDark,
        ),
        const SizedBox(width: 6),
        ...AlgoTier.values.map((tier) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Chip(
                label: tier.name[0].toUpperCase() + tier.name.substring(1),
                selected: _selectedTier == tier,
                onTap: () => setState(() {
                  _selectedTier = _selectedTier == tier ? null : tier;
                  _selectedCategory = null;
                }),
                isDark: isDark,
              ),
            )),
        ...AlgoCategory.values.map((cat) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Chip(
                label: cat.name[0].toUpperCase() + cat.name.substring(1),
                selected: _selectedCategory == cat,
                onTap: () => setState(() {
                  _selectedCategory = _selectedCategory == cat ? null : cat;
                  _selectedTier = null;
                }),
                isDark: isDark,
              ),
            )),
      ]),
    );
  }

  Widget _buildCustomAlgoCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GestureDetector(
        onTap: _openCustomAlgoRequest,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? _C.surfaceDark : _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? _C.borderDark : _C.border,
                style: BorderStyle.solid),
          ),
          child: Row(children: [
            Icon(Icons.add_rounded,
                size: 18, color: isDark ? _C.accentDark : _C.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request a Custom Strategy',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? _C.text1Dark : _C.text1)),
                    const SizedBox(height: 2),
                    Text('Have a specific strategy? We\'ll build it for you.',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? _C.text2Dark : _C.text2)),
                  ]),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: isDark ? _C.text2Dark : _C.text2),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MY ALGOS TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMyAlgosTab(bool isDark) {
    if (_userAlgosLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: 3,
        itemBuilder: (_, __) => const _AlgoCardSkeleton(),
      );
    }

    if (_userAlgos.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.auto_graph_rounded,
              size: 48, color: isDark ? _C.text2Dark : _C.text2),
          const SizedBox(height: 14),
          Text('No algos deployed yet',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? _C.text1Dark : _C.text1)),
          const SizedBox(height: 6),
          Text('Browse strategies and deploy your first algo.',
              style: GoogleFonts.inter(
                  color: isDark ? _C.text2Dark : _C.text2, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _PrimaryButton(
              label: 'Browse Marketplace',
              onTap: () => _tabController.animateTo(0),
              isDark: isDark),
        ]),
      );
    }

    return Column(children: [
      // Sync notice
      Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? _C.chipDark : _C.chip,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDark ? _C.borderDark : _C.border),
        ),
        child: Row(children: [
          Icon(Icons.sync_rounded,
              size: 13, color: isDark ? _C.text2Dark : _C.text2),
          const SizedBox(width: 8),
          Text('Changes sync within ~30 seconds',
              style: GoogleFonts.inter(
                  fontSize: 11, color: isDark ? _C.text2Dark : _C.text2)),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: _userAlgos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final algo = _userAlgos[i];
            final template = _templateForAlgo(algo);
            return _UserAlgoCard(
              algo: algo,
              template: template,
              isDark: isDark,
              onToggle: () => _toggleAlgo(algo),
              onEdit: () => _openEditSheet(algo),
              onDelete: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Delete algo?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    content: Text(
                        'Remove "${algo.name}"? This cannot be undone.',
                        style: GoogleFonts.inter(fontSize: 13)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                color: isDark ? _C.text2Dark : _C.text2)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete',
                            style: GoogleFonts.inter(
                                color: _C.red, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
                if (ok == true) _deleteAlgo(algo);
              },
            );
          },
        ),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HISTORY TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHistoryTab(bool isDark) {
    if (_historyLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: 4,
        itemBuilder: (_, __) => const _AlgoCardSkeleton(),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history_rounded,
              size: 48, color: isDark ? _C.text2Dark : _C.text2),
          const SizedBox(height: 14),
          Text('No trade history',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? _C.text1Dark : _C.text1)),
          const SizedBox(height: 6),
          Text('Executed trades will appear here.',
              style: GoogleFonts.inter(
                  color: isDark ? _C.text2Dark : _C.text2, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _HistoryCard(entry: _history[i], isDark: isDark),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ALGO CARD (Marketplace)
// ══════════════════════════════════════════════════════════════════════════════

class _AlgoCard extends StatelessWidget {
  final AlgoTemplate template;
  final bool canDeploy;
  final bool isSubscribed;
  final VoidCallback onDeploy;
  final VoidCallback onPremium;
  final bool isDark;

  const _AlgoCard({
    required this.template,
    required this.canDeploy,
    required this.isSubscribed,
    required this.onDeploy,
    required this.onPremium,
    required this.isDark,
  });

  String get _tierLabel => switch (template.tier) {
        AlgoTier.free => 'FREE',
        AlgoTier.basic => 'GTT · FREE',
        AlgoTier.premium => 'PREMIUM',
      };

  Color get _tierColor => switch (template.tier) {
        AlgoTier.free => _C.green,
        AlgoTier.basic => _C.accent,
        AlgoTier.premium => _C.amber,
      };

  @override
  Widget build(BuildContext context) {
    final isLocked = template.tier == AlgoTier.premium && !isSubscribed;
    final surface = isDark ? _C.surfaceDark : _C.surface;
    final border = isDark ? _C.borderDark : _C.border;
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top accent line — thin, only 2px
        Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            color: isDark ? _C.accentDark : _C.accent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Icon in neutral container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? _C.chipDark : _C.chip,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                child: Icon(template.icon, color: text1, size: 17),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: text1)),
                      const SizedBox(height: 2),
                      // Tier badge — text only, no heavy background
                      Text(_tierLabel,
                          style: GoogleFonts.robotoMono(
                              color: _tierColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6)),
                    ]),
              ),
              if (isLocked)
                Icon(Icons.lock_outline_rounded, size: 15, color: text2),
            ]),
            const SizedBox(height: 10),
            Text(template.description,
                style:
                    GoogleFonts.inter(color: text2, fontSize: 12, height: 1.5)),
            const SizedBox(height: 12),
            Row(children: [
              _MetaTag(label: template.category.name, isDark: isDark),
              const SizedBox(width: 6),
              _MetaTag(label: 'AI-driven', isDark: isDark),
              const Spacer(),
              isLocked
                  ? _OutlineButton(
                      label: 'Upgrade',
                      onTap: onPremium,
                      color: _C.amber,
                    )
                  : _PrimaryButton(
                      label: 'Deploy',
                      onTap: onDeploy,
                      isDark: isDark,
                      compact: true,
                    ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  USER ALGO CARD
// ══════════════════════════════════════════════════════════════════════════════

class _UserAlgoCard extends StatelessWidget {
  final UserAlgo algo;
  final AlgoTemplate? template;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDark;

  const _UserAlgoCard({
    required this.algo,
    required this.template,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _C.surfaceDark : _C.surface;
    final border = isDark ? _C.borderDark : _C.border;
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final chip = isDark ? _C.chipDark : _C.chip;
    final accent = isDark ? _C.accentDark : _C.accent;
    final isAuto = algo.executionMode == ExecutionMode.autoExecute;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: algo.isActive ? accent.withOpacity(0.4) : border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: chip,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: border),
                ),
                child: Icon(template?.icon ?? Icons.auto_graph_rounded,
                    color: text1, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(algo.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: text1)),
                      Text(template?.name ?? algo.templateId,
                          style: GoogleFonts.inter(color: text2, fontSize: 11)),
                    ]),
              ),
              // Pending badge
              if (algo.isPending)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _C.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _C.amber.withOpacity(0.3)),
                  ),
                  child: Text('SYNCING',
                      style: GoogleFonts.robotoMono(
                          fontSize: 8,
                          color: _C.amber,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ),
              // Toggle
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 22,
                  decoration: BoxDecoration(
                    color: algo.isActive
                        ? accent
                        : (isDark ? _C.borderDark : _C.border),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: algo.isActive
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(2.5),
                      width: 17,
                      height: 17,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 2)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded,
                    color: isDark ? _C.text2Dark : _C.text2, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ]),
            const SizedBox(height: 10),
            // Config tags
            Wrap(spacing: 5, runSpacing: 5, children: [
              _MetaTag(label: algo.broker.toUpperCase(), isDark: isDark),
              if (algo.aiChoosesStocks)
                _MetaTag(label: 'AI picks stocks', isDark: isDark)
              else if (algo.stockPool.isNotEmpty)
                _MetaTag(
                  label: algo.stockPool.length == 1
                      ? algo.stockPool.first
                      : '${algo.stockPool.first} +${algo.stockPool.length - 1}',
                  isDark: isDark,
                ),
              _MetaTag(
                  label: '₹${(algo.capitalAmount / 1000).toStringAsFixed(0)}k',
                  isDark: isDark),
              _MetaTag(label: 'AI picks ${algo.aiMaxPicks}', isDark: isDark),
              _MetaTag(
                  label: isAuto ? 'Auto-execute' : 'Verify first',
                  isDark: isDark),
              _StatusTag(
                  label: algo.isActive ? 'LIVE' : 'PAUSED',
                  active: algo.isActive,
                  isDark: isDark),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HISTORY CARD
// ══════════════════════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final AlgoTradeHistory entry;
  final bool isDark;
  const _HistoryCard({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? _C.surfaceDark : _C.surface;
    final border = isDark ? _C.borderDark : _C.border;
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final isProfit = entry.pnl >= 0;
    final pnlColor = isProfit
        ? (isDark ? _C.greenDark : _C.green)
        : (isDark ? _C.redDark : _C.red);
    final dateStr =
        '${entry.date.day} ${_month(entry.date.month)} ${entry.date.year}';

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(entry.algoName,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: text1)),
                  Text(dateStr,
                      style: GoogleFonts.inter(color: text2, fontSize: 11)),
                ])),
            Text(
              '${isProfit ? '+' : ''}₹${entry.pnl}',
              style: GoogleFonts.robotoMono(
                  color: pnlColor, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
              spacing: 4,
              runSpacing: 4,
              children: entry.triggeredStocks
                  .map((s) => _MetaTag(label: s, isDark: isDark))
                  .toList()),
          const SizedBox(height: 10),
          ...entry.events.map((e) => _TradeEventRow(event: e, isDark: isDark)),
          if (entry.remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline_rounded, size: 12, color: text2),
              const SizedBox(width: 6),
              Expanded(
                child: Text(entry.remark,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: text2,
                        fontStyle: FontStyle.italic)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  String _month(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}

class _TradeEventRow extends StatelessWidget {
  final TradeEvent event;
  final bool isDark;
  const _TradeEventRow({required this.event, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final isBuy = event.type == 'buy';
    final color = isBuy
        ? (isDark ? _C.greenDark : _C.green)
        : (isDark ? _C.redDark : _C.red);
    final label = switch (event.type) {
      'buy' => 'BUY',
      'sell' => 'SELL',
      'sl_hit' => 'SL',
      'target_hit' => 'TGT',
      _ => event.type.toUpperCase(),
    };
    final timeStr =
        '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(label,
              style: GoogleFonts.robotoMono(
                  color: color, fontSize: 9, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 6),
        Text(event.stock,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w500, color: text1)),
        const Spacer(),
        Text('₹${event.price.toStringAsFixed(2)}',
            style: GoogleFonts.robotoMono(fontSize: 10, color: text1)),
        const SizedBox(width: 8),
        Text('×${event.qty}',
            style: GoogleFonts.robotoMono(fontSize: 10, color: text2)),
        const SizedBox(width: 8),
        Text(timeStr, style: GoogleFonts.robotoMono(fontSize: 9, color: text2)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DEPLOY BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════

typedef DeployCallback = Future<void> Function({
  required String name,
  required String broker,
  required List<String> stockPool,
  required bool aiChoosesStocks,
  required int capitalAmount,
  required int aiMaxPicks,
  required ExecutionMode executionMode,
});

class _DeployBottomSheet extends StatefulWidget {
  final AlgoTemplate template;
  final List<String> connectedBrokers;
  final UserAlgo? existingAlgo;
  final bool isSubscribed;
  final DeployCallback onDeploy;

  const _DeployBottomSheet({
    required this.template,
    required this.connectedBrokers,
    this.existingAlgo,
    required this.isSubscribed,
    required this.onDeploy,
  });

  @override
  State<_DeployBottomSheet> createState() => _DeployBottomSheetState();
}

class _DeployBottomSheetState extends State<_DeployBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameCtrl = TextEditingController();
  String? _selectedBroker;
  final _setupKey = GlobalKey<FormState>();

  bool _setupError = false;
  bool _stocksError = false;
  String? _nameError;
  bool _brokerError = false;
  bool _stockPoolError = false;

  late meili.MeiliSearchClient _meiliClient;
  final _stockSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _stockResults = [];
  List<_SelectedStock> _stockPool = [];
  bool _stockSearching = false;
  bool _aiChoosesStocks = true;

  int _capitalAmount = 20000;
  int _aiMaxPicks = 2;
  ExecutionMode _executionMode = ExecutionMode.verifyFirst;
  bool _deploying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final existing = widget.existingAlgo;
    _nameCtrl.text = existing?.name ?? widget.template.name;
    _selectedBroker = existing?.broker ??
        (widget.connectedBrokers.isNotEmpty
            ? widget.connectedBrokers.first
            : null);
    _capitalAmount = existing?.capitalAmount ?? 20000;
    _aiMaxPicks = existing?.aiMaxPicks ?? 2;
    _aiChoosesStocks = existing?.aiChoosesStocks ?? true;
    _executionMode = existing?.executionMode ?? ExecutionMode.verifyFirst;
    if (existing != null) {
      _stockPool = existing.stockPool
          .map((s) => _SelectedStock(symbol: s, price: ''))
          .toList();
    }
    try {
      _meiliClient = meili.MeiliSearchClient(
        dotenv.env['MELIESEARCH_URL']!,
        dotenv.env['MELIE_API_KEY']!,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _stockSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchStocks(String query) async {
    if (query.isEmpty) {
      setState(() => _stockResults = []);
      return;
    }
    setState(() => _stockSearching = true);
    try {
      final res = await _meiliClient
          .index('stocks')
          .search(query, meili.SearchQuery(filter: 'type = "stock"'));
      setState(() {
        _stockResults = res.hits.cast<Map<String, dynamic>>();
        _stockSearching = false;
      });
    } catch (_) {
      setState(() => _stockSearching = false);
    }
  }

  String _cleanSymbol(String raw) => raw
      .replaceAll('NSE:', '')
      .replaceAll('-EQ', '')
      .replaceAll('-BE', '')
      .replaceAll('-BZ', '')
      .trim();

  void _addStock(Map<String, dynamic> stock) {
    if (_stockPool.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 stocks per pool')));
      return;
    }
    final sym = _cleanSymbol(stock['symbol'] ?? '');
    if (_stockPool.any((s) => s.symbol == sym)) return;
    final ltp = stock['ltp']?.toDouble() ?? 0.0;
    setState(() {
      _stockPool.add(
          _SelectedStock(symbol: sym, price: '₹${ltp.toStringAsFixed(2)}'));
      _stockSearchCtrl.clear();
      _stockResults = [];
      if (_stockPoolError) _stockPoolError = false;
      if (_stockPool.isNotEmpty) _stocksError = false;
    });
  }

  void _validateAndGoToStocks() {
    bool hasErr = false;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Name is required';
        _setupError = true;
      });
      hasErr = true;
    } else {
      setState(() => _nameError = null);
    }
    if (_selectedBroker == null) {
      setState(() {
        _brokerError = true;
        _setupError = true;
      });
      hasErr = true;
    } else {
      setState(() => _brokerError = false);
    }
    if (!hasErr) {
      setState(() => _setupError = false);
      _tabController.animateTo(1);
    }
  }

  void _validateAndGoToCapital() {
    if (!_aiChoosesStocks && _stockPool.isEmpty) {
      setState(() {
        _stockPoolError = true;
        _stocksError = true;
      });
      return;
    }
    setState(() {
      _stockPoolError = false;
      _stocksError = false;
    });
    _tabController.animateTo(2);
  }

  Future<void> _deploy() async {
    bool hasErr = false;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Name is required';
        _setupError = true;
      });
      hasErr = true;
    }
    if (_selectedBroker == null) {
      setState(() {
        _brokerError = true;
        _setupError = true;
      });
      hasErr = true;
    }
    if (!_aiChoosesStocks && _stockPool.isEmpty) {
      setState(() {
        _stockPoolError = true;
        _stocksError = true;
      });
      hasErr = true;
    }
    if (hasErr) {
      if (_setupError)
        _tabController.animateTo(0);
      else if (_stocksError) _tabController.animateTo(1);
      return;
    }
    setState(() => _deploying = true);
    await widget.onDeploy(
      name: _nameCtrl.text.trim(),
      broker: _selectedBroker!,
      stockPool:
          _aiChoosesStocks ? [] : _stockPool.map((s) => s.symbol).toList(),
      aiChoosesStocks: _aiChoosesStocks,
      capitalAmount: _capitalAmount,
      aiMaxPicks: _aiMaxPicks,
      executionMode: _executionMode,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _C.surfaceDark : _C.surface;
    final border = isDark ? _C.borderDark : _C.border;
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final accent = isDark ? _C.accentDark : _C.accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: isDark ? _C.borderDark : _C.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          widget.existingAlgo != null
                              ? 'Edit Algo'
                              : 'Configure Algo',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: text1)),
                      Text(widget.template.name,
                          style: GoogleFonts.inter(color: text2, fontSize: 12)),
                    ]),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: text2),
              ),
            ]),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              _ErrorTab(label: 'Setup', hasError: _setupError),
              _ErrorTab(label: 'Stocks', hasError: _stocksError),
              const Tab(text: 'Capital'),
              const Tab(text: 'Review'),
            ],
            labelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 12),
            labelColor: accent,
            unselectedLabelColor: text2,
            indicatorColor: accent,
            indicatorWeight: 2,
            dividerColor: border,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSetupTab(isDark, scrollController),
                _buildStocksTab(isDark, scrollController),
                _buildCapitalTab(isDark, scrollController),
                _buildSummaryTab(isDark, scrollController),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Tab 0: Setup ───────────────────────────────────────────────────────────

  Widget _buildSetupTab(bool isDark, ScrollController sc) {
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final border = isDark ? _C.borderDark : _C.border;
    final accent = isDark ? _C.accentDark : _C.accent;

    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: _setupKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Label('Algo Name', isDark: isDark),
          TextFormField(
            controller: _nameCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: text1),
            onChanged: (v) {
              if (_nameError != null && v.trim().isNotEmpty) {
                setState(() {
                  _nameError = null;
                  if (!_brokerError) _setupError = false;
                });
              }
            },
            decoration: _fieldDeco(
              isDark: isDark,
              hint: 'e.g. Morning Breakout',
              error: _nameError,
            ),
          ),
          const SizedBox(height: 16),
          _Label('Broker', isDark: isDark),
          if (widget.connectedBrokers.isEmpty)
            _InfoBanner(
              icon: Icons.warning_rounded,
              text: 'No broker connected. Go to Settings → Brokers.',
              isDark: isDark,
              isError: true,
            )
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  _brokerError ? const EdgeInsets.all(10) : EdgeInsets.zero,
              decoration: _brokerError
                  ? BoxDecoration(
                      color: _C.red.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.red.withOpacity(0.3)),
                    )
                  : const BoxDecoration(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        children: widget.connectedBrokers.map((b) {
                      final sel = _selectedBroker == b;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedBroker = b;
                            _brokerError = false;
                            if (_nameError == null) _setupError = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: sel
                                  ? accent.withOpacity(0.08)
                                  : (isDark ? _C.chipDark : _C.chip),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: sel ? accent : border,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Text(b.toUpperCase(),
                                style: GoogleFonts.robotoMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? accent : text2)),
                          ),
                        ),
                      );
                    }).toList()),
                    if (_brokerError)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text('Select a broker to continue',
                            style:
                                GoogleFonts.inter(fontSize: 11, color: _C.red)),
                      ),
                  ]),
            ),
          const SizedBox(height: 20),
          // Strategy info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? _C.chipDark : _C.chip,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(widget.template.icon, size: 14, color: text2),
                const SizedBox(width: 8),
                Text('How this strategy works',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: text1)),
              ]),
              const SizedBox(height: 8),
              Text(widget.template.description,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: text2, height: 1.5)),
              const SizedBox(height: 6),
              Text('Signal logic is managed automatically.',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: text2, fontStyle: FontStyle.italic)),
            ]),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
              label: 'Next: Pick Stocks',
              onTap: _validateAndGoToStocks,
              isDark: isDark,
              fullWidth: true),
        ]),
      ),
    );
  }

  // ── Tab 1: Stocks ──────────────────────────────────────────────────────────

  Widget _buildStocksTab(bool isDark, ScrollController sc) {
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final border = isDark ? _C.borderDark : _C.border;
    final accent = isDark ? _C.accentDark : _C.accent;
    final chip = isDark ? _C.chipDark : _C.chip;

    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // AI toggle
        GestureDetector(
          onTap: () => setState(() {
            _aiChoosesStocks = !_aiChoosesStocks;
            if (_aiChoosesStocks) {
              _stockPool.clear();
              _stockPoolError = false;
              _stocksError = false;
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _aiChoosesStocks ? accent.withOpacity(0.06) : chip,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _aiChoosesStocks ? accent.withOpacity(0.4) : border,
                width: _aiChoosesStocks ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Let AI pick stocks',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: text1)),
                      const SizedBox(height: 2),
                      Text(
                          'AI scans NSE and selects stocks matching this strategy.',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: text2, height: 1.4)),
                    ]),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 22,
                decoration: BoxDecoration(
                  color: _aiChoosesStocks
                      ? accent
                      : (isDark ? _C.borderDark : _C.border),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: _aiChoosesStocks
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(2.5),
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2)
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            Expanded(child: Divider(color: border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or add manually',
                  style: GoogleFonts.inter(fontSize: 11, color: text2)),
            ),
            Expanded(child: Divider(color: border)),
          ]),
        ),
        // Manual pool
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _aiChoosesStocks ? 0.35 : 1.0,
          child: IgnorePointer(
            ignoring: _aiChoosesStocks,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Label('Stock Pool (${_stockPool.length}/5)', isDark: isDark),
              ..._stockPool.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: chip,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                    ),
                    child: Row(children: [
                      Text(s.symbol,
                          style: GoogleFonts.robotoMono(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: text1)),
                      if (s.price.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(s.price,
                            style: GoogleFonts.robotoMono(
                                fontSize: 10, color: text2)),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _stockPool.remove(s)),
                        child:
                            Icon(Icons.close_rounded, size: 15, color: text2),
                      ),
                    ]),
                  )),
              if (_stockPool.length < 5) ...[
                Container(
                  decoration: BoxDecoration(
                    color: _stockPoolError ? _C.red.withOpacity(0.04) : chip,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _stockPoolError
                            ? _C.red.withOpacity(0.35)
                            : border),
                  ),
                  child: TextField(
                    controller: _stockSearchCtrl,
                    onChanged: _searchStocks,
                    style: GoogleFonts.inter(fontSize: 13, color: text1),
                    decoration: InputDecoration(
                      hintText: 'Search — HDFC, RELIANCE...',
                      hintStyle: GoogleFonts.inter(color: text2, fontSize: 13),
                      prefixIcon: _stockSearching
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: accent)),
                            )
                          : Icon(Icons.search_rounded, size: 18, color: text2),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ..._stockResults.take(6).map((stock) {
                  final sym = _cleanSymbol(stock['symbol'] ?? '');
                  final ltp = stock['ltp']?.toDouble() ?? 0.0;
                  final pct = stock['percent_change']?.toDouble() ?? 0.0;
                  final isPos = pct >= 0;
                  return GestureDetector(
                    onTap: () => _addStock(stock),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? _C.surfaceDark : _C.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Row(children: [
                        Text(sym,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: text1)),
                        const Spacer(),
                        Text('₹${ltp.toStringAsFixed(2)}',
                            style: GoogleFonts.robotoMono(
                                fontSize: 11, color: text1)),
                        const SizedBox(width: 8),
                        Text(
                          '${isPos ? '+' : ''}${pct.toStringAsFixed(2)}%',
                          style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              color: isPos
                                  ? (isDark ? _C.greenDark : _C.green)
                                  : (isDark ? _C.redDark : _C.red),
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.add_rounded, size: 16, color: accent),
                      ]),
                    ),
                  );
                }),
              ],
            ]),
          ),
        ),
        if (_stockPoolError && !_aiChoosesStocks) ...[
          const SizedBox(height: 10),
          _InfoBanner(
            icon: Icons.error_outline_rounded,
            text:
                'Add at least one stock, or enable "Let AI pick stocks" above.',
            isDark: isDark,
            isError: true,
          ),
        ],
        const SizedBox(height: 16),
        _PrimaryButton(
            label: 'Next: Set Capital',
            onTap: _validateAndGoToCapital,
            isDark: isDark,
            fullWidth: true),
      ]),
    );
  }

  // ── Tab 2: Capital ─────────────────────────────────────────────────────────

  Widget _buildCapitalTab(bool isDark, ScrollController sc) {
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final border = isDark ? _C.borderDark : _C.border;
    final accent = isDark ? _C.accentDark : _C.accent;
    final chip = isDark ? _C.chipDark : _C.chip;
    final perStock =
        _aiMaxPicks > 0 ? _capitalAmount ~/ _aiMaxPicks : _capitalAmount;

    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label('Capital Allocation', isDark: isDark),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('₹10k', style: GoogleFonts.inter(fontSize: 11, color: text2)),
          Text('₹${(_capitalAmount / 1000).toStringAsFixed(0)}k',
              style: GoogleFonts.robotoMono(
                  fontSize: 22, fontWeight: FontWeight.w700, color: text1)),
          Text('₹30k', style: GoogleFonts.inter(fontSize: 11, color: text2)),
        ]),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accent,
            thumbColor: accent,
            inactiveTrackColor: isDark ? _C.borderDark : _C.border,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: _capitalAmount.toDouble(),
            min: 10000,
            max: 30000,
            divisions: 20,
            onChanged: (v) => setState(() => _capitalAmount = v.toInt()),
          ),
        ),
        _InfoBanner(
          icon: Icons.info_outline_rounded,
          text: '₹30,000 max on free plan — upgrade for higher limits.',
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _Label('AI Max Picks per Signal', isDark: isDark),
        Row(
            children: List.generate(5, (i) {
          final n = i + 1;
          final sel = _aiMaxPicks == n;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 4 ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _aiMaxPicks = n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? accent : chip,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? accent : border),
                  ),
                  child: Center(
                    child: Text('$n',
                        style: GoogleFonts.robotoMono(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: sel ? Colors.white : text2)),
                  ),
                ),
              ),
            ),
          );
        })),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: chip,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            '${_aiChoosesStocks ? 'AI scans NSE' : '${_stockPool.length} stocks'} → signal fires → AI picks $_aiMaxPicks best → ₹$_capitalAmount ÷ $_aiMaxPicks = ₹${perStock.toStringAsFixed(0)} per stock',
            style:
                GoogleFonts.robotoMono(fontSize: 10, color: text2, height: 1.6),
          ),
        ),
        const SizedBox(height: 20),
        _Label('Execution Mode', isDark: isDark),
        _buildExecutionModeSelector(isDark),
        const SizedBox(height: 20),
        _PrimaryButton(
            label: 'Review & Deploy',
            onTap: () => _tabController.animateTo(3),
            isDark: isDark,
            fullWidth: true),
      ]),
    );
  }

  Widget _buildExecutionModeSelector(bool isDark) {
    final canAutoExec = widget.isSubscribed;
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final border = isDark ? _C.borderDark : _C.border;
    final chip = isDark ? _C.chipDark : _C.chip;

    Widget modeCard({
      required ExecutionMode mode,
      required String title,
      required String badge,
      required Color badgeColor,
      required String desc,
      required bool locked,
    }) {
      final sel = _executionMode == mode;
      final accent = isDark ? _C.accentDark : _C.accent;
      return GestureDetector(
        onTap: () {
          if (locked) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Auto-execute requires a Premium plan.'),
              action: SnackBarAction(
                label: 'Upgrade',
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                      context: context,
                      builder: (_) => _PremiumDialog(uid: null));
                },
              ),
            ));
            return;
          }
          setState(() => _executionMode = mode);
        },
        child: Opacity(
          opacity: locked ? 0.5 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sel ? accent.withOpacity(0.05) : chip,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel ? accent : border,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(title,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: text1)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge,
                              style: GoogleFonts.robotoMono(
                                  fontSize: 8,
                                  color: badgeColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(desc,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: text2, height: 1.4)),
                    ]),
              ),
              const SizedBox(width: 10),
              _RadioDot(
                  selected: sel, color: isDark ? _C.accentDark : _C.accent),
            ]),
          ),
        ),
      );
    }

    return Column(children: [
      modeCard(
        mode: ExecutionMode.verifyFirst,
        title: 'Verify First',
        badge: 'FREE',
        badgeColor: _C.green,
        desc:
            'Get a notification when a signal fires. You approve before any order is placed.',
        locked: false,
      ),
      modeCard(
        mode: ExecutionMode.autoExecute,
        title: 'Auto-Execute',
        badge: 'PREMIUM',
        badgeColor: _C.amber,
        desc:
            'Orders are placed instantly when a signal fires — no approval needed.',
        locked: !canAutoExec,
      ),
    ]);
  }

  // ── Tab 3: Summary ─────────────────────────────────────────────────────────

  Widget _buildSummaryTab(bool isDark, ScrollController sc) {
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final border = isDark ? _C.borderDark : _C.border;
    final accent = isDark ? _C.accentDark : _C.accent;

    final execLabel = _executionMode == ExecutionMode.autoExecute
        ? 'Auto-execute'
        : 'Verify first';
    final stockPoolLabel = _aiChoosesStocks
        ? 'AI picks from NSE'
        : _stockPool.isEmpty
            ? 'None'
            : _stockPool.map((s) => s.symbol).join(', ');

    final rows = <_SummaryRow>[
      _SummaryRow('Strategy', widget.template.name),
      _SummaryRow(
          'Name', _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim()),
      _SummaryRow('Broker', _selectedBroker?.toUpperCase() ?? '—'),
      _SummaryRow('Stock pool', stockPoolLabel),
      _SummaryRow('Capital', '₹${_capitalAmount.toStringAsFixed(0)}'),
      _SummaryRow('AI max picks', '$_aiMaxPicks stocks/signal'),
      _SummaryRow('Execution', execLabel),
    ];

    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Label('Summary', isDark: isDark),
        Container(
          decoration: BoxDecoration(
            color: isDark ? _C.surfaceDark : _C.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Column(
            children: rows.asMap().entries.map((e) {
              final isLast = e.key == rows.length - 1;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: border),
                        ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        e.value.label,
                        style: GoogleFonts.inter(fontSize: 12, color: text2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Text(
                        e.value.value,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: text1,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _InfoBanner(
          icon: _executionMode == ExecutionMode.autoExecute
              ? Icons.flash_on_rounded
              : Icons.touch_app_rounded,
          text: _executionMode == ExecutionMode.autoExecute
              ? 'Orders will fire automatically when signals are detected.'
              : 'You\'ll be notified for each signal and must approve before an order is placed.',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _InfoBanner(
          icon: Icons.sync_rounded,
          text: 'Algo enters execution queue after deploy (~30s to activate).',
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _deploying ? null : _deploy,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              disabledBackgroundColor: accent.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _deploying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Deploy Algo',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  InputDecoration _fieldDeco({
    required bool isDark,
    required String hint,
    String? error,
  }) {
    final border = isDark ? _C.borderDark : _C.border;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final chip = isDark ? _C.chipDark : _C.chip;

    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: border),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: _C.red.withOpacity(0.6)),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
          color: error != null ? _C.red : (isDark ? _C.accentDark : _C.accent),
          width: 1.5),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: text2, fontSize: 13),
      filled: true,
      fillColor: chip,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: defaultBorder,
      enabledBorder: error != null ? errorBorder : defaultBorder,
      focusedBorder: focusBorder,
      errorText: error,
      errorStyle: GoogleFonts.inter(fontSize: 11, color: _C.red),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ERROR TAB
// ══════════════════════════════════════════════════════════════════════════════

class _ErrorTab extends StatelessWidget {
  final String label;
  final bool hasError;
  const _ErrorTab({required this.label, required this.hasError});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(right: hasError ? 7 : 0),
            child: Text(label),
          ),
          if (hasError)
            Positioned(
              top: -1,
              right: -5,
              child: Container(
                width: 6,
                height: 6,
                decoration:
                    const BoxDecoration(color: _C.red, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CUSTOM ALGO REQUEST SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _CustomAlgoRequestSheet extends StatefulWidget {
  @override
  State<_CustomAlgoRequestSheet> createState() =>
      _CustomAlgoRequestSheetState();
}

class _CustomAlgoRequestSheetState extends State<_CustomAlgoRequestSheet> {
  final _strategyCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  String? _selectedTimeline;
  String? _selectedType;

  static const _timelines = ['ASAP', '1–2 weeks', '1 month', 'No rush'];
  static const _types = [
    'Intraday',
    'Swing (2–5 days)',
    'GTT / Price alert',
    'Options strategy',
    'Not sure',
  ];

  @override
  void dispose() {
    _strategyCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _C.surfaceDark : _C.surface;
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final border = isDark ? _C.borderDark : _C.border;
    final chip = isDark ? _C.chipDark : _C.chip;
    final accent = isDark ? _C.accentDark : _C.accent;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
                color: border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Request Custom Strategy',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: text1)),
                    Text(
                        'Describe your strategy — we\'ll quote a price & timeline',
                        style: GoogleFonts.inter(color: text2, fontSize: 12)),
                  ])),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: text2)),
            ]),
          ),
          Divider(height: 16, color: border),
          Expanded(
            child: SingleChildScrollView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Strategy type', isDark: isDark),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _types
                          .map((t) => GestureDetector(
                                onTap: () => setState(() => _selectedType = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _selectedType == t
                                        ? accent.withOpacity(0.08)
                                        : chip,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          _selectedType == t ? accent : border,
                                      width: _selectedType == t ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(t,
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: _selectedType == t
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _selectedType == t
                                              ? accent
                                              : text1)),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    _Label('Describe your strategy', isDark: isDark),
                    TextField(
                      controller: _strategyCtrl,
                      maxLines: 4,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: text1, height: 1.5),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Buy Nifty 50 stocks breaking 20-day high with 2× volume. Exit at +3% or −1.5%. Only 9:30–11:00 AM.',
                        hintStyle: GoogleFonts.inter(
                            color: text2, fontSize: 12, height: 1.5),
                        filled: true,
                        fillColor: chip,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: border)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Label('Budget (optional)', isDark: isDark),
                    TextField(
                      controller: _budgetCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 13, color: text1),
                      decoration: InputDecoration(
                        hintText: 'e.g. ₹2,000 or Flexible',
                        hintStyle:
                            GoogleFonts.inter(color: text2, fontSize: 13),
                        prefixText: '₹ ',
                        prefixStyle:
                            GoogleFonts.inter(color: text2, fontSize: 13),
                        filled: true,
                        fillColor: chip,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: border)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 13),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Label('Timeline', isDark: isDark),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _timelines
                          .map((t) => GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTimeline = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color:
                                        _selectedTimeline == t ? accent : chip,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _selectedTimeline == t
                                          ? accent
                                          : border,
                                    ),
                                  ),
                                  child: Text(t,
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: _selectedTimeline == t
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _selectedTimeline == t
                                              ? Colors.white
                                              : text1)),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    _InfoBanner(
                      icon: Icons.info_outline_rounded,
                      text:
                          'Our team will review your request and respond within 24 hours with a price and timeline.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () {
                          final parts = <String>[];
                          if (_selectedType != null)
                            parts.add('Type: $_selectedType');
                          if (_strategyCtrl.text.trim().isNotEmpty)
                            parts.add('Strategy: ${_strategyCtrl.text.trim()}');
                          if (_budgetCtrl.text.trim().isNotEmpty)
                            parts.add('Budget: ₹${_budgetCtrl.text.trim()}');
                          if (_selectedTimeline != null)
                            parts.add('Timeline: $_selectedTimeline');
                          final desc =
                              parts.isNotEmpty ? parts.join('\n') : null;
                          Navigator.pop(context);
                          showContactOptions(context, desc);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Submit Request',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white)),
                      ),
                    ),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BROKER CONNECT DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _BrokerConnectDialog extends StatelessWidget {
  final List<String> connectedBrokers;
  const _BrokerConnectDialog({required this.connectedBrokers});

  static const _brokerData = [
    {'id': 'zerodha', 'name': 'Zerodha', 'subtitle': 'Kite API'},
    {'id': 'fyers', 'name': 'Fyers', 'subtitle': 'Fyers API v3'},
    {'id': 'upstox', 'name': 'Upstox', 'subtitle': 'Upstox API v2'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _C.surfaceDark : _C.surface;
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final border = isDark ? _C.borderDark : _C.border;
    final chip = isDark ? _C.chipDark : _C.chip;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: surface,
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Brokers',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: text1)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: text2, size: 18)),
              ]),
              Text('Each algo uses its own broker connection.',
                  style: GoogleFonts.inter(color: text2, fontSize: 12)),
              const SizedBox(height: 16),
              ..._brokerData.map((b) {
                final isConnected = connectedBrokers.contains(b['id']);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            isConnected ? _C.green.withOpacity(0.4) : border),
                    color: isConnected ? _C.green.withOpacity(0.03) : null,
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: chip,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Icon(Icons.account_balance_rounded,
                          size: 16, color: text1),
                    ),
                    title: Text(b['name']!,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: text1)),
                    subtitle: Text(b['subtitle']!,
                        style: GoogleFonts.inter(fontSize: 11, color: text2)),
                    trailing: isConnected
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _C.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('CONNECTED',
                                style: GoogleFonts.robotoMono(
                                    color: _C.green,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          )
                        : Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: text2),
                    onTap: isConnected
                        ? null
                        : () {
                            Get.back();
                            Get.toNamed('/connect/${b['name']!.toLowerCase()}');
                          },
                  ),
                );
              }),
            ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PREMIUM DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _PremiumDialog extends StatelessWidget {
  final String? uid;
  const _PremiumDialog({this.uid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? _C.surfaceDark : _C.surface;
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: surface,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(Icons.workspace_premium_rounded, size: 20, color: _C.amber),
              const SizedBox(width: 8),
              Text('Upgrade to Premium',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 17, color: text1)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: text2, size: 18)),
            ]),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Unlock auto-execute, Buy+Sell automation, and up to 15 algos.',
                style: GoogleFonts.inter(color: text2, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            _PlanCard(
              title: 'Starter',
              price: '₹399',
              period: '/mo',
              algos: 5,
              isDark: isDark,
              features: ['5 algos', 'Auto-execute', 'Buy+Sell', 'Email alerts'],
            ),
            const SizedBox(height: 8),
            _PlanCard(
              title: 'Pro',
              price: '₹799',
              period: '/mo',
              algos: 15,
              isDark: isDark,
              isRecommended: true,
              features: [
                '15 algos',
                'All Starter features',
                'Trailing SL',
                'Priority support'
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () =>
                    {Navigator.pop(context), showContactOptions(context)},
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? _C.accentDark : _C.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('View Plans & Subscribe',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe later',
                  style: GoogleFonts.inter(color: text2, fontSize: 13)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title, price, period;
  final int algos;
  final List<String> features;
  final bool isRecommended;
  final bool isDark;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.algos,
    required this.features,
    required this.isDark,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final text1 = isDark ? _C.text1Dark : _C.text1;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final border = isDark ? _C.borderDark : _C.border;
    final accent = isDark ? _C.accentDark : _C.accent;
    final chip = isDark ? _C.chipDark : _C.chip;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRecommended ? accent : border,
          width: isRecommended ? 1.5 : 1,
        ),
        color: isRecommended ? accent.withOpacity(0.04) : chip,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 14, color: text1)),
          if (isRecommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(4)),
              child: Text('RECOMMENDED',
                  style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
            ),
          ],
          const Spacer(),
          RichText(
              text: TextSpan(children: [
            TextSpan(
                text: price,
                style: GoogleFonts.robotoMono(
                    color: text1, fontSize: 16, fontWeight: FontWeight.w700)),
            TextSpan(
                text: period,
                style: GoogleFonts.inter(color: text2, fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 5,
          children: features
              .map((f) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: _C.green, size: 12),
                      const SizedBox(width: 4),
                      Text(f,
                          style: GoogleFonts.inter(fontSize: 12, color: text1)),
                    ],
                  ))
              .toList(),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

/// Generic filter/select chip
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _C.accentDark : _C.accent;
    final chip = isDark ? _C.chipDark : _C.chip;
    final border = isDark ? _C.borderDark : _C.border;
    final text1 = isDark ? _C.text1Dark : _C.text1;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent : chip,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? accent : border),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: selected ? Colors.white : text1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12)),
      ),
    );
  }
}

/// Meta tag for algo config display
class _MetaTag extends StatelessWidget {
  final String label;
  final bool isDark;
  const _MetaTag({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final chip = isDark ? _C.chipDark : _C.chip;
    final border = isDark ? _C.borderDark : _C.border;
    final text2 = isDark ? _C.text2Dark : _C.text2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: chip,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: GoogleFonts.robotoMono(
              color: text2, fontSize: 9, fontWeight: FontWeight.w500)),
    );
  }
}

/// LIVE / PAUSED status tag
class _StatusTag extends StatelessWidget {
  final String label;
  final bool active;
  final bool isDark;
  const _StatusTag(
      {required this.label, required this.active, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (isDark ? _C.greenDark : _C.green)
        : (isDark ? _C.text2Dark : _C.text2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: GoogleFonts.robotoMono(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4)),
    );
  }
}

/// Tier badge for marketplace header
class _TierBadge extends StatelessWidget {
  final String label, sublabel;
  final Color color;
  final bool isDark;
  const _TierBadge(
      {required this.label,
      required this.sublabel,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final chip = isDark ? _C.chipDark : _C.chip;
    final border = isDark ? _C.borderDark : _C.border;
    final text2 = isDark ? _C.text2Dark : _C.text2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: chip,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.robotoMono(
                    fontWeight: FontWeight.w700, fontSize: 11, color: color)),
            Text(sublabel,
                style: GoogleFonts.inter(fontSize: 10, color: text2)),
          ]),
    );
  }
}

/// Inline info/warning banner
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final bool isError;
  const _InfoBanner(
      {required this.icon,
      required this.text,
      required this.isDark,
      this.isError = false});

  @override
  Widget build(BuildContext context) {
    final chip = isDark ? _C.chipDark : _C.chip;
    final border = isDark ? _C.borderDark : _C.border;
    final text2 = isDark ? _C.text2Dark : _C.text2;
    final iconColor = isError ? _C.red : text2;
    final bg = isError ? _C.red.withOpacity(0.04) : chip;
    final bdr = isError ? _C.red.withOpacity(0.25) : border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bdr),
      ),
      child: Row(children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 11, color: isError ? _C.red : text2, height: 1.4)),
        ),
      ]),
    );
  }
}

/// Section label
class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? _C.text2Dark : _C.text2,
              letterSpacing: 0.1)),
    );
  }
}

/// Full-width primary button
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool compact;
  final bool fullWidth;
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.isDark,
    this.compact = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? _C.accentDark : _C.accent;
    final btn = FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: compact ? const Size(72, 34) : const Size(0, 48),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 14)
            : const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : 14,
              color: Colors.white)),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Outline button (for upgrade prompts)
class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _OutlineButton(
      {required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(72, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      child: Text(label),
    );
  }
}

/// Radio dot indicator
class _RadioDot extends StatelessWidget {
  final bool selected;
  final Color color;
  const _RadioDot({required this.selected, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : Colors.grey.withOpacity(0.4),
          width: selected ? 2 : 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            )
          : null,
    );
  }
}

class _SelectedStock {
  final String symbol;
  final String price;
  _SelectedStock({required this.symbol, required this.price});
}

class _SummaryRow {
  final String label;
  final String value;
  _SummaryRow(this.label, this.value);
}
