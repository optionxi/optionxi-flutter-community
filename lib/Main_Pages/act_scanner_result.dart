import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:optionxi/Components/custom_loading_screener_result.dart';
import 'package:optionxi/Helpers/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Screener {
  final String id;
  final String name;
  final String category;
  final String timeframe;
  final DateTime createdAt;

  Screener({
    required this.id,
    required this.name,
    required this.category,
    required this.timeframe,
    required this.createdAt,
  });

  factory Screener.fromJson(Map<String, dynamic> json) {
    return Screener(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      timeframe: json['timeframe'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DataStockModel {
  final String stckname;
  final double close;
  final double pclose;
  final double high;
  final double low;
  final double open;
  final double pcnt;
  final String sec;
  final int vol;

  DataStockModel({
    required this.stckname,
    required this.close,
    required this.pclose,
    required this.high,
    required this.low,
    required this.open,
    required this.pcnt,
    required this.sec,
    required this.vol,
  });

  factory DataStockModel.fromJson(Map<String, dynamic> json) {
    return DataStockModel(
      stckname: json['stckname'] ?? '',
      close: (json['close'] ?? 0).toDouble(),
      pclose: (json['close'] ?? 0) / (1 + (json['pcnt'] ?? 0) / 100),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      pcnt: (json['pcnt'] ?? 0).toDouble(),
      sec: json['sec'] ?? '',
      vol: (json['vol'] ?? 0),
    );
  }
}

class ScannerDetailPage extends StatefulWidget {
  final String scanName;
  final String? category;

  const ScannerDetailPage({
    Key? key,
    required this.scanName,
    this.category,
  }) : super(key: key);

  @override
  State<ScannerDetailPage> createState() => _ScannerDetailPageState();
}

class _ScannerDetailPageState extends State<ScannerDetailPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;

  String _selectedCategory = 'bullish';
  List<Screener> _screeners = [];
  String _selectedScreenerId = '';
  bool _isLoadingScreeners = true;

  // Stock results variables
  List<DataStockModel> _stocks = [];
  bool _isLoadingStocks = true;
  String _search = '';
  int _currentPage = 1;
  int _totalStocks = 0;
  final int _pageSize = 20;
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category ?? 'bullish';
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedCategory == 'bullish' ? 0 : 1,
    );
    _loadScreeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScreeners() async {
    if (!mounted) return;

    setState(() {
      _isLoadingScreeners = true;
    });

    try {
      final response = await _supabase
          .from('screener_names')
          .select()
          .eq('category', _selectedCategory)
          .order('timeframe', ascending: true)
          .order('created_at', ascending: false);

      final List<Screener> fetchedScreeners =
          (response as List).map((item) => Screener.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _screeners = fetchedScreeners;

          final matchingScreener = fetchedScreeners.firstWhere(
            (screener) =>
                screener.name.toLowerCase().replaceAll(' ', '-') ==
                widget.scanName,
            orElse: () => fetchedScreeners.isNotEmpty
                ? fetchedScreeners.first
                : Screener(
                    id: '',
                    name: '',
                    category: '',
                    timeframe: '',
                    createdAt: DateTime.now()),
          );

          if (matchingScreener.id.isNotEmpty) {
            _selectedScreenerId = matchingScreener.id;
          } else if (fetchedScreeners.isNotEmpty) {
            _selectedScreenerId = fetchedScreeners.first.id;
          }
        });
      }
    } catch (error) {
      debugPrint('Error fetching screeners: $error');
      if (mounted) {
        setState(() {
          _screeners = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingScreeners = false;
        });
      }

      if (_selectedScreenerId.isNotEmpty && mounted) {
        _loadScreenerResults();
      }
    }
  }

  Future<void> _loadScreenerResults() async {
    if (_selectedScreenerId.isEmpty || !mounted) return;

    if (mounted) {
      setState(() {
        _isLoadingStocks = true;
      });
    }

    try {
      final countQuery = _supabase
          .from('screener_results')
          .select()
          .eq('screener_id', _selectedScreenerId);

      final countQueryWithSearch = _search.trim().isNotEmpty
          ? countQuery.ilike('stckname', '%${_search.trim().toUpperCase()}%')
          : countQuery;

      final countResponse = await countQueryWithSearch;
      if (!mounted) return;

      final totalCount = countResponse.length;

      final dataQuery = _supabase
          .from('screener_results')
          .select()
          .eq('screener_id', _selectedScreenerId);

      final dataQueryWithSearch = _search.trim().isNotEmpty
          ? dataQuery.ilike('stckname', '%${_search.trim().toUpperCase()}%')
          : dataQuery;

      final startIndex = (_currentPage - 1) * _pageSize;
      final response = await dataQueryWithSearch
          .order('pcnt', ascending: _sortOrder == 'asc')
          .range(startIndex, startIndex + _pageSize - 1);

      if (!mounted) return;

      final List<DataStockModel> transformedData = (response as List)
          .map((item) => DataStockModel.fromJson(item))
          .toList();

      if (mounted) {
        setState(() {
          _stocks = transformedData;
          _totalStocks = totalCount;
        });
      }
    } catch (error) {
      debugPrint('Error fetching screener results: $error');
      if (mounted) {
        setState(() {
          _stocks = [];
          _totalStocks = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStocks = false;
        });
      }
    }
  }

  void _handleCategoryChange(String value) {
    if (!mounted) return;

    setState(() {
      _selectedCategory = value;
    });

    _loadScreeners();
  }

  void _handleScreenerChange(Screener screener) {
    if (!mounted) return;

    setState(() {
      _selectedScreenerId = screener.id;
    });

    _loadScreenerResults();
  }

  void _handleSearch(String value) {
    setState(() {
      _search = value;
      _currentPage = 1;
    });
    _loadScreenerResults();
  }

  void _handlePageChange(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _loadScreenerResults();
  }

  void _handleSortToggle() {
    setState(() {
      _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
      _currentPage = 1;
    });
    _loadScreenerResults();
  }

  void _showStockDetails(DataStockModel stock) {
    Get.toNamed('/stocks/${stock.stckname.toUpperCase()}');
  }

  Widget _renderTimeframeIcon(String timeframe) {
    const double iconSize = 16.0;

    if (timeframe == 'daily') {
      return Tooltip(
        message: 'Daily timeframe',
        child: Icon(Icons.calendar_today, size: iconSize),
      );
    } else if (timeframe == 'weekly') {
      return Tooltip(
        message: 'Weekly timeframe',
        child: Icon(Icons.calendar_month, size: iconSize),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final int totalPages = (_totalStocks / _pageSize).ceil();
    final List<Screener> filteredScreeners =
        _screeners.where((s) => s.category == _selectedCategory).toList();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Screeners'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _handleCategoryChange(index == 0 ? 'bullish' : 'bearish');
          },
          tabs: const [
            Tab(
              child: Text('BULLISH',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Tab(
              child: Text('BEARISH',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Screener Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              height: 60,
              child: _isLoadingScreeners
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredScreeners.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final screener = filteredScreeners[index];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(screener.name),
                              const SizedBox(width: 4),
                              _renderTimeframeIcon(screener.timeframe),
                            ],
                          ),
                          selected: _selectedScreenerId == screener.id,
                          onSelected: (selected) {
                            if (selected) {
                              _handleScreenerChange(screener);
                            }
                          },
                          selectedColor: theme.primaryColor,
                          labelStyle: TextStyle(
                            color: _selectedScreenerId == screener.id
                                ? Colors.white
                                : null,
                          ),
                        );
                      },
                    ),
            ),

            // Search and Sort Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search stocks...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                      ),
                      onChanged: _handleSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Sort by percentage',
                    child: InkWell(
                      onTap: _handleSortToggle,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.percent,
                              size: 18,
                              color: theme.iconTheme.color,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _sortOrder == 'desc'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 16,
                              color: theme.iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: _isLoadingStocks
                  ? const Center(child: StockListSkeleton())
                  : _stocks.isEmpty
                      ? _buildNoResultsFound()
                      : _buildStockList(),
            ),

            // Pagination
            if (!_isLoadingStocks && _stocks.isNotEmpty && totalPages > 1)
              _buildPagination(totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Stocks found',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Try different filters'),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _stocks.length,
      itemBuilder: (context, index) {
        final stock = _stocks[index];
        return _buildStockListItem(stock);
      },
    );
  }

  Widget _buildStockListItem(DataStockModel stock) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = _getColorScheme(stock.pcnt, isDarkMode);
    final stockSymbol = stock.stckname.split(':')[1].split('-')[0];
    final exchange = stock.stckname.split(':')[0];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      color: colors['background'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors['borderColor']!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showStockDetails(stock),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Upper section: Stock info and current price
              Row(
                children: [
                  // Stock Icon
                  CachedNetworkImage(
                    height: 40,
                    width: 40,
                    imageUrl: Constants.OptionXiS3Loc + stockSymbol + ".png",
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          stockSymbol.isNotEmpty ? stockSymbol[0] : 'S',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/images/stockdefault.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Stock Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stockSymbol,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors['text'],
                          ),
                        ),
                        Text(
                          exchange,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${stock.close.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            stock.pcnt >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: colors['text'],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${stock.pcnt.abs().toStringAsFixed(2)}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors['text'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Divider between sections
              // Padding(
              //   padding: const EdgeInsets.symmetric(vertical: 8),
              //   child: Divider(
              //     height: 1,
              //     color: colors['borderColor']!.withValues(alpha:0.5),
              //   ),
              // ),

              // Lower section: OHLC details
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     // Open
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             'Open',
              //             style: theme.textTheme.bodySmall?.copyWith(
              //               color: theme.textTheme.bodySmall?.color
              //                   ?.withValues(alpha:0.7),
              //             ),
              //           ),
              //           Text(
              //             '₹${stock.open.toStringAsFixed(2)}',
              //             style: theme.textTheme.bodyMedium?.copyWith(
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),

              //     // High
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             'High',
              //             style: theme.textTheme.bodySmall?.copyWith(
              //               color: theme.textTheme.bodySmall?.color
              //                   ?.withValues(alpha:0.7),
              //             ),
              //           ),
              //           Text(
              //             '₹${stock.high.toStringAsFixed(2)}',
              //             style: theme.textTheme.bodyMedium?.copyWith(
              //               fontWeight: FontWeight.bold,
              //               color: Colors.green[700],
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),

              //     // Low
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             'Low',
              //             style: theme.textTheme.bodySmall?.copyWith(
              //               color: theme.textTheme.bodySmall?.color
              //                   ?.withValues(alpha:0.7),
              //             ),
              //           ),
              //           Text(
              //             '₹${stock.low.toStringAsFixed(2)}',
              //             style: theme.textTheme.bodyMedium?.copyWith(
              //               fontWeight: FontWeight.bold,
              //               color: Colors.red[700],
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),

              //     // Volume
              //     Expanded(
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Text(
              //             'Vol',
              //             style: theme.textTheme.bodySmall?.copyWith(
              //               color: theme.textTheme.bodySmall?.color
              //                   ?.withValues(alpha:0.7),
              //             ),
              //           ),
              //           Text(
              //             _formatVolume(stock.vol),
              //             style: theme.textTheme.bodyMedium?.copyWith(
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

// Helper method to format volume numbers
  // String _formatVolume(int volume) {
  //   if (volume >= 10000000) {
  //     return '${(volume / 10000000).toStringAsFixed(1)}Cr';
  //   } else if (volume >= 100000) {
  //     return '${(volume / 100000).toStringAsFixed(1)}L';
  //   } else if (volume >= 1000) {
  //     return '${(volume / 1000).toStringAsFixed(1)}K';
  //   }
  //   return volume.toString();
  // }

  Widget _buildPagination(int totalPages) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => _handlePageChange(_currentPage - 1)
                : null,
          ),
          Text(
            'Page $_currentPage of $totalPages',
            style: theme.textTheme.bodyLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () => _handlePageChange(_currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Map<String, Color?> _getColorScheme(double percentage, bool isDarkMode) {
    final colors = {
      'background': isDarkMode ? Colors.grey[900] : Colors.white,
      'text': isDarkMode ? Colors.white : Colors.black,
      'borderColor': isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
    };

    if (percentage >= 15) {
      colors['background'] = isDarkMode
          ? Colors.green[900]!.withValues(alpha: 0.3)
          : Colors.green[100]!;
      colors['text'] = isDarkMode ? Colors.green[300]! : Colors.green[800]!;
      colors['borderColor'] =
          isDarkMode ? Colors.green[800]! : Colors.green[300]!;
    } else if (percentage >= 10) {
      colors['background'] = isDarkMode
          ? Colors.green[900]!.withValues(alpha: 0.2)
          : Colors.green[50]!;
      colors['text'] = isDarkMode ? Colors.green[300]! : Colors.green[700]!;
      colors['borderColor'] =
          isDarkMode ? Colors.green[700]! : Colors.green[200]!;
    } else if (percentage >= 5) {
      colors['background'] = isDarkMode
          ? Colors.green[900]!.withValues(alpha: 0.15)
          : Colors.green[50]!;
      colors['text'] = isDarkMode ? Colors.green[300]! : Colors.green[600]!;
      colors['borderColor'] =
          isDarkMode ? Colors.green[600]! : Colors.green[200]!;
    } else if (percentage >= 2) {
      colors['background'] = isDarkMode
          ? Colors.green[900]!.withValues(alpha: 0.1)
          : const Color(0xFFA5D6A7).withValues(alpha: 0.2);
      colors['text'] = isDarkMode ? Colors.green[300]! : Colors.green;
      colors['borderColor'] = isDarkMode
          ? Colors.green[800]!.withValues(alpha: 0.4)
          : const Color(0xFFA5D6A7).withValues(alpha: 0.3);
    } else if (percentage >= 0) {
      colors['background'] = isDarkMode
          ? Colors.green[900]!.withValues(alpha: 0.05)
          : const Color(0xFFC8E6C9).withValues(alpha: 0.2);
      colors['text'] =
          isDarkMode ? Colors.green[300]! : const Color(0xFF66BB6A);
      colors['borderColor'] = isDarkMode
          ? Colors.green[800]!.withValues(alpha: 0.3)
          : const Color(0xFFC8E6C9).withValues(alpha: 0.3);
    } else if (percentage >= -2) {
      colors['background'] = isDarkMode
          ? Colors.red[900]!.withValues(alpha: 0.05)
          : const Color(0xFFFFCDD2).withValues(alpha: 0.2);
      colors['text'] = isDarkMode ? Colors.red[300]! : const Color(0xFFE53935);
      colors['borderColor'] = isDarkMode
          ? Colors.red[800]!.withValues(alpha: 0.3)
          : const Color(0xFFFFCDD2).withValues(alpha: 0.3);
    } else if (percentage >= -5) {
      colors['background'] = isDarkMode
          ? Colors.red[900]!.withValues(alpha: 0.1)
          : const Color(0xFFEF9A9A).withValues(alpha: 0.2);
      colors['text'] = isDarkMode ? Colors.red[300]! : const Color(0xFFD32F2F);
      colors['borderColor'] = isDarkMode
          ? Colors.red[800]!.withValues(alpha: 0.4)
          : const Color(0xFFEF9A9A).withValues(alpha: 0.3);
    } else if (percentage >= -10) {
      colors['background'] = isDarkMode
          ? Colors.red[900]!.withValues(alpha: 0.15)
          : const Color(0xFFE57373).withValues(alpha: 0.2);
      colors['text'] = isDarkMode ? Colors.red[300]! : const Color(0xFFC62828);
      colors['borderColor'] = isDarkMode
          ? Colors.red[800]!.withValues(alpha: 0.5)
          : const Color(0xFFE57373).withValues(alpha: 0.3);
    } else if (percentage >= -15) {
      colors['background'] = isDarkMode
          ? Colors.red[900]!.withValues(alpha: 0.2)
          : const Color(0xFFF44336).withValues(alpha: 0.2);
      colors['text'] = isDarkMode ? Colors.red[300]! : const Color(0xFFB71C1C);
      colors['borderColor'] = isDarkMode
          ? Colors.red[800]!
          : const Color(0xFFF44336).withValues(alpha: 0.3);
    } else {
      colors['background'] = isDarkMode
          ? Colors.red[900]!.withValues(alpha: 0.25)
          : const Color(0xFFC62828).withValues(alpha: 0.2);
      colors['text'] = isDarkMode ? Colors.red[300]! : const Color(0xFFB71C1C);
      colors['borderColor'] = isDarkMode
          ? Colors.red[800]!
          : const Color(0xFFC62828).withValues(alpha: 0.3);
    }

    return colors;
  }
}
