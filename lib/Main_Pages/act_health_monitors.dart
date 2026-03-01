import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Components/cust_contact_us.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Dark palette
  static const darkBg = Color(0xFF080B11);
  static const darkSurface = Color(0xFF0E1118);
  static const darkCard = Color(0xFF131720);
  static const darkBorder = Color(0x12FFFFFF);
  static const darkBorderMd = Color(0x1EFFFFFF);
  static const darkText = Color(0xFFECF0F8);
  static const darkTextSub = Color(0xFF8899B0);
  static const darkTextMuted = Color(0xFF3D4A5C);

  // Light palette
  static const lightBg = Color(0xFFF2F5FA);
  static const lightSurface = Color(0xFFE8EDF5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0x0D000000);
  static const lightBorderMd = Color(0x18000000);
  static const lightText = Color(0xFF0D1520);
  static const lightTextSub = Color(0xFF5C6B80);
  static const lightTextMuted = Color(0xFFB0BCC8);

  // Status colours
  static const green = Color(0xFF10D374);
  static const greenBorder = Color(0x3010D374);
  static const greenBg = Color(0x0C10D374);
  static const red = Color(0xFFF04A59);
  static const redBorder = Color(0x30F04A59);
  static const redBg = Color(0x0CF04A59);
  static const amber = Color(0xFFF5A623);
  static const amberBorder = Color(0x30F5A623);
  static const amberBg = Color(0x0CF5A623);
  static const gray = Color(0xFF5A6679);
  static const purple = Color(0xFF8B5CF6);

  // Accent
  static const accent = Color(0xFF3B82F6);

  static Color statusDot(String s) => switch (s.toLowerCase()) {
        'up' => green,
        'down' => red,
        'maintenance' => purple,
        'pending' => amber,
        'paused' => gray,
        _ => gray,
      };

  static Color statusFg(String s) => switch (s.toLowerCase()) {
        'up' => green,
        'down' => red,
        'maintenance' => purple,
        'pending' => amber,
        'paused' => gray,
        _ => gray,
      };

  static String statusLabel(String s) => switch (s.toLowerCase()) {
        'up' => 'Operational',
        'down' => 'Down',
        'maintenance' => 'Maintenance',
        'pending' => 'Pending',
        'paused' => 'Paused',
        _ => s,
      };

  static (Color, Color, Color) bannerColors(OverallHealth h) => switch (h) {
        OverallHealth.operational => (green, greenBg, greenBorder),
        OverallHealth.partial => (amber, amberBg, amberBorder),
        OverallHealth.major => (red, redBg, redBorder),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
enum OverallHealth { operational, partial, major }

class MonitorStatus {
  final String id, name, status;
  const MonitorStatus(
      {required this.id, required this.name, required this.status});
}

class StatusPayload {
  final OverallHealth overall;
  final List<MonitorStatus> monitors;
  const StatusPayload({required this.overall, required this.monitors});
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────
class _StatusService {
  final String baseUrl;
  _StatusService(this.baseUrl);

  Future<StatusPayload> fetch() async {
    final res = await http
        .get(Uri.parse('$baseUrl/api/status'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final overall = switch ((j['overall'] as String?) ?? '') {
      'partial' => OverallHealth.partial,
      'major' => OverallHealth.major,
      _ => OverallHealth.operational,
    };
    final monitors = (j['monitors'] as List? ?? [])
        .map((m) => MonitorStatus(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? 'Heartbeat',
              status: m['status']?.toString() ?? 'unknown',
            ))
        .toList();
    return StatusPayload(overall: overall, monitors: monitors);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root Widget
// ─────────────────────────────────────────────────────────────────────────────
class HealthDashboard extends StatefulWidget {
  const HealthDashboard({super.key});

  @override
  State<HealthDashboard> createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard>
    with TickerProviderStateMixin {
  late final _StatusService _svc;
  StatusPayload? _data;
  String? _error;
  bool _loading = true;
  DateTime? _updatedAt;
  Timer? _timer;

  late final AnimationController _fadeCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _headerCtrl;

  @override
  void initState() {
    super.initState();
    _svc = _StatusService(dotenv.env['BASE_URL_HEALTH']!);

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _load();
    _timer =
        Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final payload = await _svc.fetch();
      if (!mounted) return;
      setState(() {
        _data = payload;
        _error = null;
        _loading = false;
        _updatedAt = DateTime.now();
      });
      _fadeCtrl.forward(from: 0);
      _headerCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _timeAgo(DateTime dt) {
    final s = DateTime.now().difference(dt).inSeconds;
    if (s < 60) return '${s}s ago';
    if (s < 3600) return '${s ~/ 60}m ago';
    return '${s ~/ 3600}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? _T.darkBg : _T.lightBg;
    final card = isDark ? _T.darkCard : _T.lightCard;
    final border = isDark ? _T.darkBorder : _T.lightBorder;
    final borderMd = isDark ? _T.darkBorderMd : _T.lightBorderMd;
    final text = isDark ? _T.darkText : _T.lightText;
    final textSub = isDark ? _T.darkTextSub : _T.lightTextSub;
    final muted = isDark ? _T.darkTextMuted : _T.lightTextMuted;
    final surface = isDark ? _T.darkSurface : _T.lightSurface;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: _T.accent,
        backgroundColor: card,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Enhanced Header ─────────────────────────────────────────────
            _SliverHeader(
              isDark: isDark,
              bg: bg,
              surface: surface,
              card: card,
              border: border,
              borderMd: borderMd,
              text: text,
              textSub: textSub,
              muted: muted,
              loading: _loading,
              updatedAt: _updatedAt,
              onRefresh: _load,
              onBack: () => Navigator.of(context).maybePop(),
              timeAgo: _updatedAt != null ? _timeAgo(_updatedAt!) : null,
              data: _data,
              pulseCtrl: _pulseCtrl,
            ),

            // ── Body ────────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_loading)
                    _Skeleton(isDark: isDark, card: card, border: border)
                  else if (_error != null)
                    _ErrorState(
                      message: _error!,
                      onRetry: _load,
                      card: card,
                      border: border,
                      text: text,
                      textSub: textSub,
                    )
                  else if (_data != null)
                    FadeTransition(
                      opacity: CurvedAnimation(
                          parent: _fadeCtrl, curve: Curves.easeOut),
                      child: _Body(
                        data: _data!,
                        pulseCtrl: _pulseCtrl,
                        card: card,
                        border: border,
                        text: text,
                        textSub: textSub,
                        muted: muted,
                        isDark: isDark,
                        onReportOutage: () => showContactOptions(context),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enhanced Sliver Header
// ─────────────────────────────────────────────────────────────────────────────
class _SliverHeader extends StatelessWidget {
  final bool isDark, loading;
  final Color bg, surface, card, border, borderMd, text, textSub, muted;
  final DateTime? updatedAt;
  final String? timeAgo;
  final StatusPayload? data;
  final AnimationController pulseCtrl;
  final VoidCallback onRefresh, onBack;

  const _SliverHeader({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.card,
    required this.border,
    required this.borderMd,
    required this.text,
    required this.textSub,
    required this.muted,
    required this.loading,
    required this.updatedAt,
    required this.timeAgo,
    required this.data,
    required this.pulseCtrl,
    required this.onRefresh,
    required this.onBack,
  });

  int get _upCount => data?.monitors.where((m) => m.status == 'up').length ?? 0;
  int get _totalCount => data?.monitors.length ?? 0;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: _HeaderContainer(
        isDark: isDark,
        bg: bg,
        surface: surface,
        border: border,
        borderMd: borderMd,
        text: text,
        textSub: textSub,
        muted: muted,
        loading: loading,
        timeAgo: timeAgo,
        data: data,
        pulseCtrl: pulseCtrl,
        upCount: _upCount,
        totalCount: _totalCount,
        onRefresh: onRefresh,
        onBack: onBack,
      ),
    );
  }
}

class _HeaderContainer extends StatelessWidget {
  final bool isDark, loading;
  final Color bg, surface, border, borderMd, text, textSub, muted;
  final String? timeAgo;
  final StatusPayload? data;
  final AnimationController pulseCtrl;
  final int upCount, totalCount;
  final VoidCallback onRefresh, onBack;

  const _HeaderContainer({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.border,
    required this.borderMd,
    required this.text,
    required this.textSub,
    required this.muted,
    required this.loading,
    required this.timeAgo,
    required this.data,
    required this.pulseCtrl,
    required this.upCount,
    required this.totalCount,
    required this.onRefresh,
    required this.onBack,
  });

  Color get _overallColor {
    if (data == null) return _T.gray;
    return switch (data!.overall) {
      OverallHealth.operational => _T.green,
      OverallHealth.partial => _T.amber,
      OverallHealth.major => _T.red,
    };
  }

  String get _overallLabel {
    if (data == null) return 'Loading…';
    return switch (data!.overall) {
      OverallHealth.operational => 'All Systems Go',
      OverallHealth.partial => 'Partial Outage',
      OverallHealth.major => 'Major Outage',
    };
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? _T.darkSurface : _T.lightCard,
        border: Border(
          bottom: BorderSide(color: borderMd),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Navigation row ──────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(12, topPad + 10, 12, 0),
            child: Row(
              children: [
                // Back button
                _NavButton(
                  isDark: isDark,
                  border: border,
                  onTap: onBack,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14, color: textSub),
                ),
                const Spacer(),
                // Refresh button
                _NavButton(
                  isDark: isDark,
                  border: border,
                  onTap: onRefresh,
                  child: loading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: textSub),
                        )
                      : Icon(Icons.refresh_rounded, size: 18, color: textSub),
                ),
              ],
            ),
          ),

          // ── Main header content ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Infrastructure\nMonitor',
                        style: GoogleFonts.dmSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: text,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Overall status badge
                    if (data != null)
                      _OverallBadge(
                        color: _overallColor,
                        label: _overallLabel,
                        pulseCtrl: pulseCtrl,
                        isDark: isDark,
                      ),
                  ],
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),

          // ── Section label ───────────────────────────────────────────────
          if (data != null && !loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(
                    'SERVICES',
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: muted,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(height: 1, color: border),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${data!.monitors.length} monitors',
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      color: muted,
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

// ─────────────────────────────────────────────────────────────────────────────
// Overall Badge (top-right of header title)
// ─────────────────────────────────────────────────────────────────────────────
class _OverallBadge extends StatelessWidget {
  final Color color;
  final String label;
  final AnimationController pulseCtrl;
  final bool isDark;

  const _OverallBadge({
    required this.color,
    required this.label,
    required this.pulseCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: color, size: 8, ctrl: pulseCtrl),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav Button (back / refresh)
// ─────────────────────────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final bool isDark;
  final Color border;
  final VoidCallback onTap;
  final Widget child;

  const _NavButton({
    required this.isDark,
    required this.border,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0x14FFFFFF) : const Color(0x08000000),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final StatusPayload data;
  final AnimationController pulseCtrl;
  final Color card, border, text, textSub, muted;
  final bool isDark;
  final VoidCallback onReportOutage;

  const _Body({
    required this.data,
    required this.pulseCtrl,
    required this.card,
    required this.border,
    required this.text,
    required this.textSub,
    required this.muted,
    required this.isDark,
    required this.onReportOutage,
  });

  @override
  Widget build(BuildContext context) {
    final divider = isDark ? const Color(0x0AFFFFFF) : const Color(0x08000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),

        // ── Overall banner ─────────────────────────────────────────────────
        _OverallBanner(
          overall: data.overall,
          pulseCtrl: pulseCtrl,
          text: text,
          textSub: textSub,
        ),
        const SizedBox(height: 12),

        // ── Monitor list ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: data.monitors.asMap().entries.map((entry) {
              final i = entry.key;
              final monitor = entry.value;
              final isLast = i == data.monitors.length - 1;
              return Column(
                children: [
                  _MonitorRow(
                    monitor: monitor,
                    text: text,
                    textSub: textSub,
                    isDark: isDark,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: divider,
                      indent: 46,
                      endIndent: 0,
                    ),
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // ── Report Outage ──────────────────────────────────────────────────
        _ReportOutageButton(onTap: onReportOutage, isDark: isDark),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overall Banner (compact version in body)
// ─────────────────────────────────────────────────────────────────────────────
class _OverallBanner extends StatelessWidget {
  final OverallHealth overall;
  final AnimationController pulseCtrl;
  final Color text, textSub;

  const _OverallBanner({
    required this.overall,
    required this.pulseCtrl,
    required this.text,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    final (accent, bg, border) = _T.bannerColors(overall);

    final (icon, title, subtitle) = switch (overall) {
      OverallHealth.operational => (
          Icons.check_circle_rounded,
          'All Systems Operational',
          'All services are running normally',
        ),
      OverallHealth.partial => (
          Icons.warning_amber_rounded,
          'Partial Service Disruption',
          'Some services are experiencing issues',
        ),
      OverallHealth.major => (
          Icons.cancel_rounded,
          'Major System Outage',
          'Multiple services are currently down',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          _PulseDot(color: accent, size: 10, ctrl: pulseCtrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: accent.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: accent, size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monitor Row
// ─────────────────────────────────────────────────────────────────────────────
class _MonitorRow extends StatelessWidget {
  final MonitorStatus monitor;
  final Color text, textSub;
  final bool isDark;

  const _MonitorRow({
    required this.monitor,
    required this.text,
    required this.textSub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = _T.statusDot(monitor.status);
    final labelColor = _T.statusFg(monitor.status);
    final statusLabel = _T.statusLabel(monitor.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          // Dot with glow
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withOpacity(0.55),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Service name
          Expanded(
            child: Text(
              monitor.name,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: labelColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: labelColor.withOpacity(0.22)),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.dmMono(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: labelColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Outage Button
// ─────────────────────────────────────────────────────────────────────────────
class _ReportOutageButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _ReportOutageButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _T.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.red.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 16, color: _T.red),
            const SizedBox(width: 8),
            Text(
              'Report an Outage',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _T.red,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing Dot
// ─────────────────────────────────────────────────────────────────────────────
class _PulseDot extends StatelessWidget {
  final Color color;
  final double size;
  final AnimationController ctrl;

  const _PulseDot({
    required this.color,
    required this.size,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final v = ctrl.value;
        return SizedBox(
          width: size + 10,
          height: size + 10,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: size + 8 * v,
              height: size + 8 * v,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15 * (1 - v * 0.7)),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 7)
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color card, border, text, textSub;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.card,
    required this.border,
    required this.text,
    required this.textSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.red.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _T.red.withOpacity(0.09),
              shape: BoxShape.circle,
              border: Border.all(color: _T.red.withOpacity(0.2)),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: _T.red, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Failed',
            style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: text,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmMono(fontSize: 11, color: textSub),
          ),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: _T.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.accent.withOpacity(0.3)),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _T.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Loader
// ─────────────────────────────────────────────────────────────────────────────
class _Skeleton extends StatefulWidget {
  final bool isDark;
  final Color card, border;

  const _Skeleton({
    required this.isDark,
    required this.card,
    required this.border,
  });

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({
    double height = 16,
    double? width,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final base =
            widget.isDark ? const Color(0xFF111520) : const Color(0xFFFFFFFF);
        final hi =
            widget.isDark ? const Color(0xFF1C2333) : const Color(0xFFF0F3F8);
        final t = _ctrl.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [base, hi, base],
              stops: [
                (t - 0.3).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider =
        widget.isDark ? const Color(0x0AFFFFFF) : const Color(0x08000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _box(height: 70, radius: 14),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: widget.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: List.generate(
                8,
                (i) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            children: [
                              _box(width: 8, height: 8, radius: 4),
                              const SizedBox(width: 14),
                              Expanded(child: _box(height: 13, radius: 6)),
                              const SizedBox(width: 20),
                              _box(width: 80, height: 26, radius: 13),
                            ],
                          ),
                        ),
                        if (i < 7)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: divider,
                            indent: 22,
                          ),
                      ],
                    )),
          ),
        ),
        const SizedBox(height: 24),
        _box(height: 50, radius: 14),
      ],
    );
  }
}
