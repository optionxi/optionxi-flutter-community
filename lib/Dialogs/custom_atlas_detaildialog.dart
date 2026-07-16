import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optionxi/Main_Pages/MarketSentiments/act_market_sentiments.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert'; // Add this import for jsonDecode

class AtlasDetailDialog extends StatefulWidget {
  final AtlasOutput output;

  const AtlasDetailDialog({
    Key? key,
    required this.output,
  }) : super(key: key);

  static void show(BuildContext context, AtlasOutput output) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AtlasDetailDialog(output: output),
    );
  }

  @override
  _AtlasDetailDialogState createState() => _AtlasDetailDialogState();
}

class _AtlasDetailDialogState extends State<AtlasDetailDialog> {
  // Track expanded sections similar to React implementation
  Map<String, bool> expandedSections = {
    'statistics': true,
    'direction': true,
    'positive': true,
    'negative': false,
    'neutral': false,
  };

  void toggleSection(String section) {
    setState(() {
      expandedSections[section] = !(expandedSections[section] ?? false);
    });
  }

  Map<String, dynamic> parseIndicatorList(String indicatorListStr) {
    Map<String, dynamic> result = {};

    if (indicatorListStr.isEmpty) {
      return result;
    }

    try {
      // Replace single quotes with double quotes for valid JSON
      String jsonStr = indicatorListStr.replaceAll("'", '"');
      result = Map<String, dynamic>.from(jsonDecode(jsonStr));
    } catch (e) {
      // Fallback to the original string parsing method if JSON parsing fails
      // Split the string by commas
      List<String> pairs = indicatorListStr.split(',');

      for (String pair in pairs) {
        // Split each pair by colon
        final parts = pair.split(':');
        if (parts.length == 2) {
          // Trim whitespace and add to map
          final key = parts[0].trim();
          final value = parts[1].trim();
          result[key] = value;
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final textTheme = themeData.textTheme;
    final isDarkMode = themeData.brightness == Brightness.dark;

    // Calculate the height to use approximately 90% of screen height
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.9;

    return Container(
      height: bottomSheetHeight,
      decoration: BoxDecoration(
        color: themeData.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bottom sheet drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Dialog header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _getSignalIcon(widget.output.type),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.output.type} Signal Details',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d y h:mm a')
                          .format(DateTime.parse(widget.output.createdAt)),
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(DateTime.parse(widget.output.createdAt)),
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Market Statistics Section
                  _buildCollapsibleSection(
                    title: 'Market Statistics',
                    icon: Icon(Icons.info, color: Colors.blue),
                    section: 'statistics',
                    content: _buildStatisticsContent(isDarkMode),
                  ),

                  const SizedBox(height: 16),

                  // Trend Direction Section
                  _buildCollapsibleSection(
                    title: 'Trend Direction',
                    icon: Icon(Icons.trending_up, color: Colors.purple),
                    section: 'direction',
                    content: _buildDirectionContent(),
                  ),

                  const SizedBox(height: 16),

                  // Positive Indicators Section
                  _buildCollapsibleSection(
                    title: 'Positive Indicators',
                    icon: Icon(Icons.arrow_circle_up, color: Colors.green),
                    section: 'positive',
                    count: widget.output.positiveIndicators,
                    content: _buildIndicatorsContent(
                      'positive',
                      widget.output.positiveIndicatorsList,
                      Colors.green,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Negative Indicators Section
                  _buildCollapsibleSection(
                    title: 'Negative Indicators',
                    icon: Icon(Icons.arrow_circle_down, color: Colors.red),
                    section: 'negative',
                    count: widget.output.negativeIndicators,
                    content: _buildIndicatorsContent(
                      'negative',
                      widget.output.negativeIndicatorsList,
                      Colors.red,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Neutral Indicators Section
                  _buildCollapsibleSection(
                    title: 'Neutral Indicators',
                    icon: Icon(Icons.remove_circle, color: Colors.amber),
                    section: 'neutral',
                    count: widget.output.neutralIndicators,
                    content: _buildIndicatorsContent(
                      'neutral',
                      widget.output.neutralIndicatorsList,
                      Colors.amber,
                    ),
                  ),

                  // Add some bottom padding for better scrolling experience
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required Icon icon,
    required String section,
    int? count,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        InkWell(
          onTap: () => toggleSection(section),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    count != null ? '$title ($count)' : title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Icon(
                  expandedSections[section] ?? false
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),

        // Divider
        const Divider(height: 1),

        // Collapsible Content
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: content,
          ),
          secondChild: const SizedBox(height: 0),
          crossFadeState: (expandedSections[section] ?? false)
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildStatisticsContent(bool isDarkMode) {
    final bgColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50;

    // Changed from GridView to Row with expanded children to prevent overflow
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Probability',
            '${widget.output.probability}%',
            null,
            bgColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Advancing',
            '${widget.output.advancing}',
            Colors.green,
            bgColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Declining',
            '${widget.output.declining}',
            Colors.red,
            bgColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color? valueColor, Color bgColor) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Add this to minimize vertical space
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionContent() {
    // Changed from GridView to Row with two flexible children to prevent overflow
    return Row(
      children: [
        Expanded(
          child: _buildDirectionItem('Long Term', widget.output.longterm),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDirectionItem('Short Term', widget.output.shortterm),
        ),
      ],
    );
  }

  Widget _buildDirectionItem(String label, String value) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            _getSignalIcon(value),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Minimize vertical space
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsContent(
    String type,
    String indicatorsList,
    Color color,
  ) {
    final indicators = parseIndicatorList(indicatorsList);

    if (indicators.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Text('No ${type.toLowerCase()} indicators'),
        ),
      );
    }

    // Modified to use ListView.builder instead of GridView for better flexibility
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: indicators.length,
      itemBuilder: (context, index) {
        final entry = indicators.entries.elementAt(index);
        final key = entry.key.replaceAll(RegExp(r'Web_|_'), ' ').trim();
        final value = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _getIndicatorIcon(type, color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: '$key: ',
                      style: TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: '$value',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getSignalIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bull':
        return const Icon(Icons.trending_up, color: Colors.green);
      case 'bear':
        return const Icon(Icons.trending_down, color: Colors.red);
      default:
        return const Icon(Icons.remove, color: Colors.grey);
    }
  }

  Widget _getIndicatorIcon(String type, Color color) {
    switch (type.toLowerCase()) {
      case 'positive':
        return Icon(Icons.arrow_circle_up, color: color, size: 18);
      case 'negative':
        return Icon(Icons.arrow_circle_down, color: color, size: 18);
      case 'neutral':
        return Icon(Icons.remove_circle, color: color, size: 18);
      default:
        return Icon(Icons.circle, color: color, size: 18);
    }
  }
}
