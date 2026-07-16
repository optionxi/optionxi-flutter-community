import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Main_Pages/Community/community_home_page.dart';
import 'package:optionxi/Main_Pages/Community/fastapi_discourse_service.dart';

class CommunitySyncGate extends StatefulWidget {
  const CommunitySyncGate({super.key});

  @override
  State<CommunitySyncGate> createState() => _CommunitySyncGateState();
}

class _CommunitySyncGateState extends State<CommunitySyncGate> {
  bool _synced = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  Future<void> _sync() async {
    try {
      await CommunityService.syncUser();
      if (mounted) setState(() => _synced = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_synced) return const CommunityHomePage();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Community',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Center(
        child:
            _error != null ? _ErrorView(onRetry: _retry) : const _LoadingView(),
      ),
    );
  }

  void _retry() {
    setState(() => _error = null);
    _sync();
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(strokeWidth: 2),
        const SizedBox(height: 16),
        Text(
          'Connecting…',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded,
            size: 40, color: cs.onSurface.withOpacity(0.35)),
        const SizedBox(height: 12),
        Text(
          'Could not connect to Community',
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onRetry,
          child: Text('Retry', style: GoogleFonts.dmSans()),
        ),
      ],
    );
  }
}
