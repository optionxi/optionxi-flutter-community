import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optionxi/Helpers/browser_lite_widget.dart';
import 'package:optionxi/Helpers/open_url.dart';

class BrowserLite_V extends StatefulWidget {
  final String url;

  const BrowserLite_V(
    this.url, {
    Key? key,
  }) : super(key: key);

  @override
  State<BrowserLite_V> createState() => _BrowserLite_VState();
}

class _BrowserLite_VState extends State<BrowserLite_V> {
  String _currentTitle = '';

  @override
  void initState() {
    super.initState();
    _currentTitle = 'Browser';
  }

  void _handleBackPress() {
    Navigator.of(context).pop();
  }

  void _openInExternalBrowser() {
    OpenHelper.open_url(widget.url);
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: widget.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('URL copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.open_in_browser,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Open in External Browser',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openInExternalBrowser();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.copy,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Copy URL',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _copyUrl();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: _handleBackPress,
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.url.isNotEmpty)
              Text(
                Uri.parse(widget.url).host,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onBackground.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, size: 22),
            onPressed: _openInExternalBrowser,
            tooltip: 'Open in External Browser',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            onPressed: _showMoreOptions,
            tooltip: 'More Options',
          ),
        ],
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Browser content
            Expanded(
              child: BrowserLite_Widget(
                widget.url,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
