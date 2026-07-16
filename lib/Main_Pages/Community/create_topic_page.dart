// lib/pages/Community/create_topic_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optionxi/Main_Pages/AlgoDeploy/algo_page.dart';
import 'package:optionxi/Main_Pages/Community/dm_community_model.dart';
import 'package:optionxi/Main_Pages/Community/fastapi_discourse_service.dart';

// ─── Discourse field requirements ─────────────────────────────────────────────
// Title  : 15 – 255 characters  (min_topic_title_length default = 15)
// Body   : 20 – 32 000 characters (min_post_length default = 20)
// These are the Discourse defaults; adjust if your instance overrides them.
const int _kMinTitleLen = 15;
const int _kMaxTitleLen = 255;
const int _kMinBodyLen = 20;
const int _kMaxBodyLen = 32000;

class CreateTopicPage extends StatefulWidget {
  final List<Category> categories;
  const CreateTopicPage({super.key, required this.categories});

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  Category? _selectedCat;
  bool _submitting = false;

  // Validation state
  String? _titleError;
  String? _bodyError;

  bool get _isDark => ThemeController.instance.isDarkMode;

  // ─── Theme helpers ─────────────────────────────────────────────────────────
  Color get _bg => _isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF4F4FA);
  Color get _surface =>
      _isDark ? const Color(0xFF12121A) : const Color(0xFFFFFFFF);
  Color get _card =>
      _isDark ? const Color(0xFF1A1A26) : const Color(0xFFFFFFFF);
  Color get _border =>
      _isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE0E0EE);
  Color get _text =>
      _isDark ? const Color(0xFFEEEEF5) : const Color(0xFF0F0F1A);
  Color get _muted =>
      _isDark ? const Color(0xFF8888AA) : const Color(0xFF7777AA);
  static const _kAccent = Color(0xFF6C63FF);

  // ─── Validation ────────────────────────────────────────────────────────────
  String? _validateTitle(String v) {
    final len = v.trim().length;
    if (len == 0) return 'Title is required.';
    if (len < _kMinTitleLen) {
      return 'Title must be at least $_kMinTitleLen characters (currently $len).';
    }
    if (len > _kMaxTitleLen) {
      return 'Title must be no longer than $_kMaxTitleLen characters.';
    }
    return null;
  }

  String? _validateBody(String v) {
    final len = v.trim().length;
    if (len == 0) return 'Content is required.';
    if (len < _kMinBodyLen) {
      return 'Content must be at least $_kMinBodyLen characters (currently $len).';
    }
    if (len > _kMaxBodyLen) {
      return 'Content is too long (max $_kMaxBodyLen characters).';
    }
    return null;
  }

  bool _runValidation() {
    final te = _validateTitle(_titleCtrl.text);
    final be = _validateBody(_bodyCtrl.text);
    setState(() {
      _titleError = te;
      _bodyError = be;
    });
    return te == null && be == null;
  }

  // ─── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_runValidation()) return;

    setState(() => _submitting = true);
    try {
      await CommunityService.createTopic(
        title: _titleCtrl.text.trim(),
        raw: _bodyCtrl.text.trim(),
        categoryId: _selectedCat?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e',
                style: GoogleFonts.dmSans(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Color _catColor(String hex) {
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _kAccent;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: _muted),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Topic',
          style: GoogleFonts.dmSans(
            color: _text,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kAccent,
                    ),
                  )
                : GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kAccent, Color(0xFF9C88FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Post',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Category picker ────────────────────────────────────────────────
          if (widget.categories.isNotEmpty) ...[
            _sectionLabel('CATEGORY'),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.categories.map((cat) {
                  final selected = _selectedCat?.id == cat.id;
                  final color = _catColor(cat.color);
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCat = selected ? null : cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color.withOpacity(0.2) : _card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? color : _border,
                        ),
                      ),
                      child: Text(
                        cat.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: selected ? color : _muted,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Title ──────────────────────────────────────────────────────────
          _sectionLabel('TITLE'),
          const SizedBox(height: 8),
          _buildTitleField(),
          if (_titleError != null) ...[
            const SizedBox(height: 6),
            _errorText(_titleError!),
          ],
          // Character count hint
          _charCountRow(
            _titleCtrl.text.trim().length,
            _kMinTitleLen,
            _kMaxTitleLen,
          ),

          const SizedBox(height: 20),

          // ── Body ───────────────────────────────────────────────────────────
          _sectionLabel('CONTENT'),
          const SizedBox(height: 8),
          _buildBodyField(),
          if (_bodyError != null) ...[
            const SizedBox(height: 6),
            _errorText(_bodyError!),
          ],
          _charCountRow(
            _bodyCtrl.text.trim().length,
            _kMinBodyLen,
            _kMaxBodyLen,
          ),

          const SizedBox(height: 16),

          // ── Markdown tip ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: _kAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supports Markdown: **bold**, *italic*, `code`, > quote',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 11,
          color: _muted,
          letterSpacing: 1.2,
        ),
      );

  Widget _errorText(String msg) => Row(
        children: [
          const Icon(Icons.error_outline, size: 13, color: Colors.redAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      );

  Widget _charCountRow(int current, int min, int max) {
    final tooShort = current > 0 && current < min;
    final tooLong = current > max;
    final ok = current >= min && current <= max;
    final color = tooLong
        ? Colors.redAccent
        : tooShort
            ? _muted
            : ok
                ? _kAccent2
                : _muted;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$current / $max',
            style: GoogleFonts.spaceMono(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  // Separate into named methods so setState rebuilds are efficient
  Widget _buildTitleField() => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _titleError != null ? Colors.redAccent : _border,
          ),
        ),
        child: TextField(
          controller: _titleCtrl,
          style: GoogleFonts.dmSans(
            color: _text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Give your topic a clear title…',
            hintStyle: GoogleFonts.dmSans(color: _muted, fontSize: 16),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          minLines: 1,
          maxLength: _kMaxTitleLen,
          onChanged: (_) {
            // Clear error on change; re-validate on submit
            if (_titleError != null) {
              setState(() => _titleError = _validateTitle(_titleCtrl.text));
            } else {
              setState(() {}); // refresh char count
            }
          },
        ),
      );

  Widget _buildBodyField() => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _bodyError != null ? Colors.redAccent : _border,
          ),
        ),
        child: TextField(
          controller: _bodyCtrl,
          style: GoogleFonts.dmSans(color: _text, fontSize: 14, height: 1.6),
          decoration: InputDecoration(
            hintText:
                'Share your thoughts, questions, or ideas…\n\nMarkdown is supported.',
            hintStyle:
                GoogleFonts.dmSans(color: _muted, fontSize: 14, height: 1.6),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
          maxLines: null,
          minLines: 10,
          maxLength: _kMaxBodyLen,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          onChanged: (_) {
            if (_bodyError != null) {
              setState(() => _bodyError = _validateBody(_bodyCtrl.text));
            } else {
              setState(() {}); // refresh char count
            }
          },
        ),
      );

  // Unused _kAccent2 avoidance — expose it so the compiler doesn't warn
  static const _kAccent2 = Color(0xFF00D4AA);
}
