// ─────────────────────────────────────────────────────────────────────────
// Community Algos — browse publicly shared backtest setups, view one in
// detail, and optionally save ("clone") it into your own saved algos.
//
// Reads/writes `community_algos` directly via Supabase — no Firebase auth
// required to browse or publish. Saving a copy into the user's own algos
// still goes through BacktestApiService (which IS Firebase-authenticated,
// since that's writing to *their* saved algos).
//
// Wire up from SavedBacktestsPage's `_browseMajorAlgos`:
//
//   Future<void> _browseMajorAlgos() async {
//     final saved = await Navigator.push<bool>(context, MaterialPageRoute(
//       builder: (_) => CommunityAlgosBrowsePage(api: _api),
//     ));
//     if (saved == true) _load();
//   }
// ─────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:optionxi/Main_Pages/IndicatorBacktest/indicator-backtest.dart';

const String kCommunityAlgosTable = 'community_algos';

// ─────────────────────────────────────────────
// THEME (matches indicator-backtest.dart's _T)
// ─────────────────────────────────────────────
class _CT {
  static const accent = Color(0xFF5B7FFF);
  static const violet = Color(0xFF9B6DFF);
  static const green = Color(0xFF00C896);
  static const red = Color(0xFFFF4D6D);
  static const amber = Color(0xFFFFAB00);

  static Color bg(bool d) =>
      d ? const Color(0xFF0B0D15) : const Color(0xFFF0F2F8);
  static Color surface(bool d) => d ? const Color(0xFF161927) : Colors.white;
  static Color surface2(bool d) =>
      d ? const Color(0xFF1E2235) : const Color(0xFFF7F8FF);
  static Color border(bool d) =>
      d ? const Color(0xFF252840) : const Color(0xFFE4E7F2);
  static Color text(bool d) =>
      d ? const Color(0xFFEEF0FF) : const Color(0xFF0F1124);
  static Color sub(bool d) =>
      d ? const Color(0xFF7880A0) : const Color(0xFF8890B0);

  static const gradient = LinearGradient(colors: [accent, violet]);
}

void _snack(BuildContext context, String msg, {required bool ok}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: ok ? _CT.green : _CT.red, size: 16),
      const SizedBox(width: 8),
      Expanded(
          child: Text(msg,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFEEF0FF),
                  fontWeight: FontWeight.w500))),
    ]),
    backgroundColor: const Color(0xFF252840),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(12),
    duration: const Duration(seconds: 3),
  ));
}

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────

class CommunityAlgoModel {
  final String id;
  final String creatorName;
  final String? creatorAvatarUrl;
  final String name;
  final String? description;
  final String symbol;
  final int days;
  final String direction;
  final int confirmBars;
  final List<ConditionModel> conditions;
  final double? hitRate;
  final int? matchedBars;
  final int? confirmed;
  final int? failed;
  final int? totalBars;
  final int cloneCount;
  final bool isFeatured;
  final DateTime createdAt;

  CommunityAlgoModel({
    required this.id,
    required this.creatorName,
    this.creatorAvatarUrl,
    required this.name,
    this.description,
    required this.symbol,
    required this.days,
    required this.direction,
    required this.confirmBars,
    required this.conditions,
    this.hitRate,
    this.matchedBars,
    this.confirmed,
    this.failed,
    this.totalBars,
    this.cloneCount = 0,
    this.isFeatured = false,
    required this.createdAt,
  });

  factory CommunityAlgoModel.fromJson(Map<String, dynamic> j) =>
      CommunityAlgoModel(
        id: j['id'].toString(),
        creatorName: j['creator_name'] ?? 'Anonymous',
        creatorAvatarUrl: j['creator_avatar_url'],
        name: j['name'] ?? '',
        description: j['description'],
        symbol: j['symbol'] ?? 'NIFTY',
        days: j['days'] ?? 14,
        direction: j['direction'] ?? 'Bullish',
        confirmBars: j['confirm_bars'] ?? 3,
        conditions: ((j['conditions'] as List?) ?? [])
            .map((c) => ConditionModel.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        hitRate: (j['hit_rate'] as num?)?.toDouble(),
        matchedBars: j['matched_bars'],
        confirmed: j['confirmed'],
        failed: j['failed'],
        totalBars: j['total_bars'],
        cloneCount: j['clone_count'] ?? 0,
        isFeatured: j['is_featured'] ?? false,
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

enum _SortMode { featured, topHitRate, mostCloned, newest }

// ─────────────────────────────────────────────
// BROWSE PAGE
// ─────────────────────────────────────────────

class CommunityAlgosBrowsePage extends StatefulWidget {
  final BacktestApiService api;
  const CommunityAlgosBrowsePage({super.key, required this.api});

  @override
  State<CommunityAlgosBrowsePage> createState() =>
      _CommunityAlgosBrowsePageState();
}

class _CommunityAlgosBrowsePageState extends State<CommunityAlgosBrowsePage> {
  List<CommunityAlgoModel> _algos = [];
  bool _loading = true;
  String? _error;
  _SortMode _sort = _SortMode.featured;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var query = Supabase.instance.client.from(kCommunityAlgosTable).select();
      final PostgrestTransformBuilder<List<Map<String, dynamic>>> sorted;
      switch (_sort) {
        case _SortMode.featured:
          sorted = query
              .order('is_featured', ascending: false)
              .order('hit_rate', ascending: false, nullsFirst: false);
          break;
        case _SortMode.topHitRate:
          sorted = query.order('hit_rate', ascending: false, nullsFirst: false);
          break;
        case _SortMode.mostCloned:
          sorted = query.order('clone_count', ascending: false);
          break;
        case _SortMode.newest:
          sorted = query.order('created_at', ascending: false);
          break;
      }
      final res = await sorted.limit(100);
      if (!mounted) return;
      setState(() {
        _algos = (res as List)
            .map((e) =>
                CommunityAlgoModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(CommunityAlgoModel algo) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityAlgoDetailPage(api: widget.api, algo: algo),
      ),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    return Scaffold(
      backgroundColor: _CT.bg(dark),
      appBar: AppBar(
        backgroundColor: _CT.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Browse Algos',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _CT.text(dark))),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: _CT.border(dark))),
      ),
      body: Column(children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              _sortChip(dark, 'Featured', _SortMode.featured),
              const SizedBox(width: 8),
              _sortChip(dark, 'Top hit rate', _SortMode.topHitRate),
              const SizedBox(width: 8),
              _sortChip(dark, 'Most cloned', _SortMode.mostCloned),
              const SizedBox(width: 8),
              _sortChip(dark, 'Newest', _SortMode.newest),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.error_outline_rounded,
                              size: 40, color: _CT.red),
                          const SizedBox(height: 10),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: _CT.sub(dark))),
                          const SizedBox(height: 12),
                          TextButton(
                              onPressed: _load, child: const Text('Retry')),
                        ]),
                      ),
                    )
                  : _algos.isEmpty
                      ? Center(
                          child: Text('No community algos yet',
                              style: TextStyle(color: _CT.sub(dark))))
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _CT.accent,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _algos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => _openDetail(_algos[i]),
                              child: _CommunityAlgoCard(
                                  algo: _algos[i], dark: dark),
                            ),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _sortChip(bool dark, String label, _SortMode mode) {
    final sel = _sort == mode;
    return GestureDetector(
      onTap: () {
        if (_sort == mode) return;
        setState(() => _sort = mode);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? _CT.accent : _CT.surface(dark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? _CT.accent : _CT.border(dark)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : _CT.text(dark))),
      ),
    );
  }
}

class _CommunityAlgoCard extends StatelessWidget {
  final CommunityAlgoModel algo;
  final bool dark;
  const _CommunityAlgoCard({required this.algo, required this.dark});

  @override
  Widget build(BuildContext context) {
    final bullish = algo.direction == 'Bullish';
    final dirColor = bullish ? _CT.green : _CT.red;
    final hr = algo.hitRate;
    Color hrColor = _CT.sub(dark);
    if (hr != null)
      hrColor = hr >= 60 ? _CT.green : (hr >= 40 ? _CT.amber : _CT.red);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _CT.surface(dark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CT.border(dark)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: _CT.accent.withOpacity(0.15),
                  backgroundImage: algo.creatorAvatarUrl != null
                      ? NetworkImage(algo.creatorAvatarUrl!)
                      : null,
                  child: algo.creatorAvatarUrl == null
                      ? Icon(Icons.person_rounded, size: 14, color: _CT.accent)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(algo.creatorName,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _CT.sub(dark)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (algo.isFeatured)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _CT.amber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('FEATURED',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _CT.amber)),
                  ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Icon(
                    bullish
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: dirColor,
                    size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(algo.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _CT.text(dark)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                  '${algo.symbol} · ${algo.direction} · ${algo.days}d lookback',
                  style: TextStyle(fontSize: 11, color: _CT.sub(dark))),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.copy_all_rounded, size: 13, color: _CT.sub(dark)),
                const SizedBox(width: 4),
                Text('${algo.cloneCount} saved',
                    style: TextStyle(fontSize: 11, color: _CT.sub(dark))),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: _CT.sub(dark)),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          _hitRateRing(hr, hrColor, dark),
        ],
      ),
    );
  }

  Widget _hitRateRing(double? hr, Color color, bool dark) {
    final pct = (hr ?? 0).clamp(0, 100) / 100;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: hr != null ? pct.toDouble() : 0,
              strokeWidth: 5,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hr != null ? '${hr.toStringAsFixed(0)}%' : '—',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color),
              ),
              Text('acc',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: _CT.sub(dark))),
            ],
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────
// DETAIL PAGE
// ─────────────────────────────────────────────

class CommunityAlgoDetailPage extends StatefulWidget {
  final BacktestApiService api;
  final CommunityAlgoModel algo;
  const CommunityAlgoDetailPage(
      {super.key, required this.api, required this.algo});

  @override
  State<CommunityAlgoDetailPage> createState() =>
      _CommunityAlgoDetailPageState();
}

class _CommunityAlgoDetailPageState extends State<CommunityAlgoDetailPage> {
  bool _saving = false;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Future<void> _saveToMyAlgos() async {
    setState(() => _saving = true);
    try {
      final myAlgos = await widget.api.listAlgos();
      final plan = await widget.api.getUserPlan();
      final limit = algoLimitForPlan(plan);
      if (myAlgos.length >= limit) {
        if (mounted) {
          _showUpgradeDialog(plan);
        }
        return;
      }

      final algo = widget.algo;
      await widget.api.createAlgo(
        name: algo.name,
        symbol: algo.symbol,
        days: algo.days,
        direction: algo.direction,
        confirmBars: algo.confirmBars,
        conditions: algo.conditions,
      );

      // Best-effort — a failed clone-count bump shouldn't block the save.
      try {
        await Supabase.instance.client.rpc('increment_community_algo_clone',
            params: {'algo_id': algo.id});
      } catch (_) {}

      if (!mounted) return;
      _snack(context, 'Saved to your algos!', ok: true);
      // Navigator.pop(context, true);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SavedBacktestsPage()),
        (route) =>
            route.isFirst, // keeps Home at the base, drops everything else
      );
    } catch (e) {
      if (mounted) _snack(context, e.toString(), ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showUpgradeDialog(String plan) {
    final dark = _isDark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _CT.surface(dark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Limit reached',
            style:
                TextStyle(color: _CT.text(dark), fontWeight: FontWeight.w700)),
        content: Text(
          plan.toLowerCase() == 'max'
              ? 'You\'ve reached the maximum limit of $kMaxAlgoLimit algos.'
              : 'You\'ve reached your saved-algo limit for the $plan plan. Upgrade for more capacity.',
          style: TextStyle(color: _CT.sub(dark), fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: _CT.sub(dark)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark;
    final algo = widget.algo;
    final bullish = algo.direction == 'Bullish';
    final dirColor = bullish ? _CT.green : _CT.red;
    final hr = algo.hitRate;
    Color hrColor = _CT.sub(dark);
    if (hr != null)
      hrColor = hr >= 60 ? _CT.green : (hr >= 40 ? _CT.amber : _CT.red);

    return Scaffold(
      backgroundColor: _CT.bg(dark),
      appBar: AppBar(
        backgroundColor: _CT.surface(dark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Algo Details',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _CT.text(dark))),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: _CT.border(dark))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _CT.accent.withOpacity(0.15),
              backgroundImage: algo.creatorAvatarUrl != null
                  ? NetworkImage(algo.creatorAvatarUrl!)
                  : null,
              child: algo.creatorAvatarUrl == null
                  ? Icon(Icons.person_rounded, size: 20, color: _CT.accent)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(algo.creatorName,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _CT.text(dark))),
                    Text('${algo.cloneCount} people saved this',
                        style: TextStyle(fontSize: 11, color: _CT.sub(dark))),
                  ]),
            ),
            if (algo.isFeatured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: _CT.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('FEATURED',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _CT.amber)),
              ),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _CT.surface(dark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _CT.border(dark)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                    bullish
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: dirColor,
                    size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(algo.name,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _CT.text(dark))),
                ),
              ]),
              if (algo.description != null &&
                  algo.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(algo.description!,
                    style: TextStyle(fontSize: 13, color: _CT.sub(dark))),
              ],
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill(dark, algo.symbol),
                _pill(dark, algo.direction, color: dirColor),
                _pill(dark, '${algo.days}d lookback'),
                _pill(dark, 'Confirm in ${algo.confirmBars} bars'),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _CT.surface(dark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _CT.border(dark)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Track record',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _CT.text(dark))),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _stat('Matched', '${algo.matchedBars ?? 0}', _CT.text(dark)),
                  _stat('Confirmed', '${algo.confirmed ?? 0}', _CT.green),
                  _stat('Failed', '${algo.failed ?? 0}', _CT.red),
                  _stat('Total bars', '${algo.totalBars ?? 0}', _CT.sub(dark)),
                  _stat('Hit rate',
                      hr != null ? '${hr.toStringAsFixed(1)}%' : '—', hrColor),
                  _stat('Cloned', '${algo.cloneCount}x', _CT.accent),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _CT.surface(dark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _CT.border(dark)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Conditions',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _CT.text(dark))),
              const SizedBox(height: 10),
              for (final c in algo.conditions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: _CT.surface2(dark),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(c.summary,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _CT.text(dark))),
                  ),
                ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: _CT.surface(dark),
          border: Border(top: BorderSide(color: _CT.border(dark))),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
                gradient: _CT.gradient,
                borderRadius: BorderRadius.circular(14)),
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveToMyAlgos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_rounded,
                      size: 18, color: Colors.white),
              label: const Text('Save to my algos',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(bool dark, String label, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: (color ?? _CT.accent).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (color ?? _CT.accent).withOpacity(0.3))),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color ?? _CT.accent)),
      );

  Widget _stat(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: color)),
              Text(label,
                  style: TextStyle(fontSize: 9, color: _CT.sub(_isDark))),
            ]),
      );
}
