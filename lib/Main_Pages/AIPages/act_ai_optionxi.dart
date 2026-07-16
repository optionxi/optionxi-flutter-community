import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:optionxi/Components/cust_contact_us.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:optionxi/Main_Pages/Achivements/fastapi_achivement.dart';
import 'package:optionxi/Theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

String backendApiUrl = "";

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ThemeController themeController = Get.find<ThemeController>();

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _sessions = [];
  bool _isSending = false;
  bool _isLoading = true;

  // FAQ & Quota State
  List<Map<String, dynamic>> _predefinedQuestions = [];
  bool _isPremium = false;
  int _dailyMessageCount = 0;
  int get _dailyLimit => _isPremium ? 300 : 30;

  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    backendApiUrl = dotenv.env['BACKEND_CHAT_API_URL']!;
    _initializeChat();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) AchievementEvents.openedAIChat();
    });
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await Future.wait([
      _checkPremiumStatus(),
      _fetchDailyUsage(),
      _fetchHistory(),
      _fetchPredefinedQuestions(),
    ]);

    // Scroll to bottom after loading history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _subscribeToRealtime();
  }

  // --- Quota & Premium Checks ---

  Future<void> _checkPremiumStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isPremium = response != null;
        });
      }
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      if (mounted) {
        setState(() => _isPremium = false);
      }
    }
  }

  Future<void> _fetchDailyUsage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Get start of today in UTC
      final now = DateTime.now().toUtc();
      final startOfDay =
          DateTime.utc(now.year, now.month, now.day).toIso8601String();

      final count = await supabase
          .from('chat_sessions')
          .count(CountOption.exact)
          .eq('suid', uid)
          .gte('created_at', startOfDay);

      if (mounted) {
        setState(() {
          _dailyMessageCount = count;
        });
      }
    } catch (e) {
      debugPrint("Error fetching daily usage: $e");
    }
  }

  Future<void> _fetchPredefinedQuestions() async {
    try {
      // Fetch more questions initially so we can show them in the "More" drawer
      final data = await supabase
          .from('chat_questions')
          .select('question, tool_id')
          .order('created_at', ascending: true)
          .limit(50);

      if (mounted) {
        setState(() {
          _predefinedQuestions = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Failed to load questions: $e');
    }
  }

  void _subscribeToRealtime() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _subscription?.unsubscribe();

    _subscription = supabase
        .channel('chat_sessions_updates_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'suid',
            value: uid,
          ),
          callback: (payload) => _handleRealtimeUpdate(payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'suid',
            value: uid,
          ),
          callback: (payload) => _handleRealtimeUpdate(payload),
        )
        .subscribe();
  }

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    final newRecord = Map<String, dynamic>.from(payload.newRecord);

    setState(() {
      if (payload.eventType == PostgresChangeEvent.insert) {
        _sessions.insert(0, newRecord);
        // Increment usage count locally
        _dailyMessageCount++;

        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else if (payload.eventType == PostgresChangeEvent.update) {
        final index = _sessions.indexWhere((s) => s['id'] == newRecord['id']);
        if (index != -1) {
          _sessions[index] = newRecord;
        }
      }
    });
  }

  Future<void> _fetchHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await supabase
          .from('chat_sessions')
          .select()
          .eq('suid', uid)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _sessions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage({
    String? message,
    List<String>? tools,
  }) async {
    final msgToSend = message ?? _controller.text.trim();

    // Basic validation including quota
    if (msgToSend.isEmpty || _isSending) return;
    if (_dailyMessageCount >= _dailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Daily limit reached. Upgrade for more."),
          action:
              SnackBarAction(label: 'Upgrade', onPressed: _showUpgradeDialog),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      if (message == null) {
        _controller.clear();
      }

      final response = await http.post(
        Uri.parse('$backendApiUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': msgToSend,
          'tools': tools ?? [],
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Unknown error';
        throw Exception('Server error: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error sending message: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _navigateToStock(String stockName) {
    Navigator.pushNamed(context, '/stocks/$stockName');
  }

  void _showUpgradeDialog() {
    // Implement your upgrade navigation or dialog here
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Upgrade to Premium"),
        content: const Text("Get 300 messages per day and exclusive insights."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => {showContactOptions(ctx)},
              child: const Text("Upgrade Now")),
        ],
      ),
    );
  }

  void _openAllQuestionsDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Questions',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("All Questions",
                              style: Theme.of(context).textTheme.titleLarge),
                          IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _predefinedQuestions.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final q = _predefinedQuestions[index];
                        return _buildCompressedQuestionCard(
                            Theme.of(context),
                            q['question'],
                            List<String>.from(q['tool_id'] ?? []), onTap: () {
                          Navigator.pop(context); // Close drawer
                          _sendMessage(
                              message: q['question'],
                              tools: List<String>.from(q['tool_id'] ?? []));
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("OptionXI AI"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.titleLarge?.color,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeController.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _isLoading = true);
                    _fetchHistory();
                    _fetchPredefinedQuestions();
                    _fetchDailyUsage();
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Quota Header ---
            _buildQuotaHeader(theme),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                        backgroundColor:
                            isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                    )
                  : _sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ask me anything about the market',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: _sessions.length,
                          itemBuilder: (context, index) {
                            return _ChatBubble(
                              key: ValueKey(_sessions[index]['id']),
                              session: _sessions[index],
                              onStockTap: _navigateToStock,
                            );
                          },
                        ),
            ),

            // --- FAQ Section (Always at bottom) ---
            if (_predefinedQuestions.isNotEmpty) _buildFAQHorizontalList(theme),

            _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    // Determine color based on usage percentage
    final percentage = _dailyMessageCount / _dailyLimit;
    Color statusColor = Colors.green;
    if (percentage > 0.7) statusColor = Colors.orange;
    if (percentage >= 1.0) statusColor = Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        border: Border(
            bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  "$_dailyMessageCount / $_dailyLimit",
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!_isPremium)
            TextButton(
              onPressed: _showUpgradeDialog,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  Text("Upgrade Limit",
                      style: TextStyle(
                          // color: theme.primaryColor,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFAQHorizontalList(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    // Show first 5 in the quick bar, user can click "More" for the rest
    final displayQuestions = _predefinedQuestions.take(5).toList();

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayQuestions.length + 1, // +1 for "More" button
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          if (index == displayQuestions.length) {
            // "More" Button
            return Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: ActionChip(
                elevation: 0,
                backgroundColor: isDark
                    ? Colors.grey[800]
                    : theme.primaryColor.withOpacity(0.1),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 12), // Taller
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                label: Row(
                  children: [
                    Text("View More",
                        style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(Icons.list, size: 16, color: theme.primaryColor),
                  ],
                ),
                onPressed: _openAllQuestionsDrawer,
              ),
            );
          }

          final questionData = displayQuestions[index];
          final question = questionData['question'] as String;
          final tools = List<String>.from(questionData['tool_id'] ?? []);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => _sendMessage(message: question, tools: tools),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 200,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Reusable card for the vertical "All Questions" drawer
  Widget _buildCompressedQuestionCard(
      ThemeData theme, String question, List<String> tools,
      {required VoidCallback onTap}) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.1)),
              child: Icon(
                Icons.auto_graph,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isSending,
              style: TextStyle(
                color: isDark ? Colors.grey[200] : Colors.grey[800],
              ),
              decoration: InputDecoration(
                hintText: "Ask a question about stocks...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isSending ? null : () => _sendMessage(),
            mini: true,
            elevation: 0,
            backgroundColor: _isSending
                ? (isDark ? Colors.grey[700] : Colors.grey[300])
                : theme.primaryColor,
            child: _isSending
                ? SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      backgroundColor:
                          isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                  )
                : const Icon(Icons.arrow_upward, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// --- CHAT BUBBLE WIDGET (Unchanged logic, just styling) ---
class _ChatBubble extends StatefulWidget {
  final Map<String, dynamic> session;
  final Function(String) onStockTap;

  const _ChatBubble({
    super.key,
    required this.session,
    required this.onStockTap,
  });

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool _showAllStocks = false;

  String formatStockName(String rawName) {
    String name = rawName.toUpperCase();
    if (name.startsWith('NSE:')) name = name.substring(4);
    if (name.startsWith('BSE:')) name = name.substring(4);
    name = name.replaceAll(RegExp(r'-EQ$'), '');
    name = name.replaceAll(RegExp(r'-BZ$'), '');
    return name.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final session = widget.session;
    final status = session['status'];
    final isCompleted = status == 'completed';
    final tools = List<String>.from(session['tools'] ?? []);
    final stocks = List<String>.from(session['stocks'] ?? []);

    DateTime? createdAt;
    if (session['created_at'] != null) {
      createdAt = DateTime.tryParse(session['created_at'])?.toLocal();
    }

    const int initialShowCount = 3;
    final visibleStocks =
        _showAllStocks ? stocks : stocks.take(initialShowCount).toList();
    final hiddenCount = stocks.length - initialShowCount;
    final showMoreColor = isDarkMode ? Colors.white : theme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 14,
                  child: Icon(Icons.person_outline, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session['message'] ?? '...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.grey[200] : Colors.grey[900],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
            ),
            if (isCompleted && session['result'] != null)
              MarkdownBody(
                data: session['result'],
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
                  ),
                  code: TextStyle(
                    backgroundColor:
                        isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                    fontFamily: 'monospace',
                  ),
                  a: TextStyle(color: theme.primaryColor),
                ),
              )
            else
              _buildProgress(session, theme),
            if (stocks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mentioned Stocks',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: visibleStocks.map((rawStockName) {
                  final fmtStock = formatStockName(rawStockName);

                  return InkWell(
                    onTap: () => widget.onStockTap(rawStockName),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl:
                                    "${Constants.OptionXiS3Loc}$fmtStock.png",
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Image.asset(
                                  'assets/images/stockdefault.png',
                                  fit: BoxFit.cover,
                                ),
                                errorWidget: (context, url, error) =>
                                    Image.asset(
                                  'assets/images/stockdefault.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fmtStock,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.grey[200]
                                        : Colors.grey[900],
                                  ),
                                ),
                                Text(
                                  rawStockName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[400],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (stocks.length > initialShowCount)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showAllStocks = !_showAllStocks;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showAllStocks
                                ? "Show Less"
                                : "Show $hiddenCount More",
                            style: TextStyle(
                              color: showMoreColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Icon(
                            _showAllStocks
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: showMoreColor,
                            size: 16,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (tools.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tools
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  )
                else
                  const Spacer(),
                if (createdAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color:
                              isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        timeago.format(createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color:
                              isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(Map<String, dynamic> session, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final progress = ((session['progress'] ?? 0) / 100.0).clamp(0.0, 1.0);
    final statusMsg = session['status_message'] ?? 'Initializing...';
    final status = session['status'];
    final isError = status == 'error';

    final Color progressBackgroundColor = isError
        ? (isDarkMode
            ? Colors.red.shade900.withOpacity(0.5)
            : Colors.red.withOpacity(0.05))
        : (isDarkMode
            ? Colors.grey[800]!
            : theme.primaryColor.withOpacity(0.05));

    final Color progressIndicatorColor =
        isDarkMode ? Colors.white : theme.primaryColor;

    final Color statusTextColor = isError
        ? (isDarkMode ? Colors.red.shade200 : Colors.red.shade700)
        : (isDarkMode ? Colors.grey[200]! : theme.primaryColor);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: progressBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isError
                ? (isDarkMode
                    ? Colors.red.shade700
                    : Colors.red.withOpacity(0.2))
                : (isDarkMode
                    ? Colors.grey[700]!
                    : theme.primaryColor.withOpacity(0.1)),
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isError)
                Icon(
                  Icons.error_outline,
                  color: statusTextColor,
                  size: 16,
                )
              else
                SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: progressIndicatorColor,
                    backgroundColor:
                        isDarkMode ? Colors.grey[600] : Colors.grey[200],
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusMsg,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (!isError) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDarkMode
                    ? Colors.grey[600]
                    : theme.primaryColor.withOpacity(0.1),
                valueColor:
                    AlwaysStoppedAnimation<Color>(progressIndicatorColor),
                minHeight: 4,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
