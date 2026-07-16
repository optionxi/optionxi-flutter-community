import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:optionxi/VirtualTradeJournal/db_read_supabase_journal_portfolio.dart';
import 'package:optionxi/VirtualTrading/VDataModel/v_tradehistory.dart';

class JournalAnalyticsController extends GetxController {
  final String? suid;
  JournalAnalyticsController({this.suid});

  late final String userSuid;
  final PortfolioJournalService _service = PortfolioJournalService();

  // ── Loading ────────────────────────────────────
  final RxBool isInitialLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool hasError = false.obs;

  // ── All fetched trades (full loaded window) ────
  /// Raw data fetched from backend. Views filter this client-side.
  final RxList<JournalTradeHistory> allTrades = <JournalTradeHistory>[].obs;

  /// Filtered trades exposed to the active view (calendar/weekly/chart/list).
  /// For chart & list views this equals allTrades (filtered by their own UI).
  /// For calendar/weekly it is filtered to the focused month/week.
  final RxList<JournalTradeHistory> trades = <JournalTradeHistory>[].obs;

  // ── Active range label shown in banner ────────
  /// e.g. "6M", "Mar 2025", "10 Mar – 16 Mar"
  final RxString rangeLabel = '6M'.obs;

  // ── Loaded window (what we have in allTrades) ─
  /// How many days back from today we have fetched.
  final RxInt loadedDays = 180.obs;

  // ── Active view filter window ─────────────────
  // Used only for calendar/weekly: trim allTrades client-side.
  DateTime? _viewFrom;
  DateTime? _viewTo;

  // ── Preset options ─────────────────────────────
  static const List<({String label, int days})> presets = [
    (label: '7D', days: 7),
    (label: '30D', days: 30),
    (label: '3M', days: 90),
    (label: '6M', days: 180),
    (label: '1Y', days: 365),
    (label: 'All', days: 3650),
  ];

  // ── Stale-guard + debounce ─────────────────────
  int _token = 0;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    userSuid = suid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    // Default: fetch last 6 months, show all of it.
    loadedDays.value = 180;
    _viewFrom = null;
    _viewTo = null;
    _fetch(initial: true);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  // ── Public API ─────────────────────────────────

  /// User tapped a preset chip (7D / 30D / 3M …).
  /// Always expands the loaded window if needed; never refetches smaller.
  void applyPreset(int days) {
    rangeLabel.value = presets
        .firstWhere((p) => p.days == days, orElse: () => presets[1])
        .label;
    _viewFrom = null;
    _viewTo = null;
    if (days > loadedDays.value) {
      // Need to fetch a wider window.
      loadedDays.value = days;
      _scheduleFetch();
    } else {
      // Data already in allTrades — just reapply the view filter.
      _applyViewFilter();
    }
  }

  /// Calendar view navigated to [month].
  /// Does NOT re-fetch unless the month is outside the loaded window.
  /// Updates [trades] client-side and updates the banner label.
  void applyMonth(DateTime month) {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    _viewFrom = from;
    _viewTo = to;
    rangeLabel.value = '${_mon(month.month)} ${month.year}';

    final daysNeeded = DateTime.now().difference(from).inDays + 1;
    if (daysNeeded > loadedDays.value) {
      // User navigated further back than our loaded window → expand.
      loadedDays.value = daysNeeded.clamp(1, 3650);
      _scheduleFetch();
    } else {
      _applyViewFilter();
    }
  }

  /// Weekly view navigated to the week starting on [weekStart] (Monday).
  /// Does NOT re-fetch unless the week is outside the loaded window.
  void applyWeek(DateTime weekStart) {
    final weekEnd = weekStart
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    _viewFrom = weekStart;
    _viewTo = weekEnd;
    rangeLabel.value = '${weekStart.day} ${_mon(weekStart.month)} – '
        '${weekEnd.day} ${_mon(weekEnd.month)}';

    final daysNeeded = DateTime.now().difference(weekStart).inDays + 1;
    if (daysNeeded > loadedDays.value) {
      loadedDays.value = daysNeeded.clamp(1, 3650);
      _scheduleFetch();
    } else {
      _applyViewFilter();
    }
  }

  /// Chart view requests a specific day window.
  /// Expands the loaded window if needed; uses cached data otherwise.
  void ensureChartDays(int days) {
    if (days > loadedDays.value) {
      loadedDays.value = days;
      _scheduleFetch();
    }
    // Chart view always filters allTrades itself — no need to update [trades].
  }

  /// Clears calendar/weekly filter and shows all loaded data.
  void clearViewFilter() {
    _viewFrom = null;
    _viewTo = null;
    _applyViewFilter();
  }

  Future<void> refresh() => _fetch(initial: false);

  // ── Private ────────────────────────────────────

  /// Applies the active [_viewFrom]/[_viewTo] window to [allTrades]
  /// and writes the result to [trades].
  void _applyViewFilter() {
    if (_viewFrom == null && _viewTo == null) {
      trades.assignAll(allTrades);
      return;
    }
    final from = _viewFrom;
    final to = _viewTo;
    trades.assignAll(allTrades.where((t) {
      if (from != null && t.exitDate.isBefore(from)) return false;
      if (to != null && t.exitDate.isAfter(to)) return false;
      return true;
    }).toList());
  }

  void _scheduleFetch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _fetch(initial: false);
    });
  }

  Future<void> _fetch({required bool initial}) async {
    final token = ++_token;
    hasError(false);
    initial ? isInitialLoading(true) : isRefreshing(true);

    try {
      final history = await _service.fetchTradeHistory(
        userSuid,
        days: loadedDays.value.clamp(1, 3650),
      );

      if (token != _token) return;

      // Store the complete fetched set (newest-first keeps existing order).
      allTrades.assignAll(history.reversed.toList());

      // Then apply the current view filter.
      _applyViewFilter();
    } catch (e, st) {
      if (token != _token) return;
      hasError(true);
      print('JournalAnalyticsController error: $e\n$st');
    } finally {
      if (token == _token) {
        isInitialLoading(false);
        isRefreshing(false);
      }
    }
  }

  static String _mon(int m) => const [
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
