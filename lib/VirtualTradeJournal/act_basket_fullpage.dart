import 'package:flutter/material.dart';
import 'package:optionxi/VirtualTradeJournal/vt_frag_portfolio_journal.dart';

class BasketFullPage extends StatefulWidget {
  const BasketFullPage({Key? key}) : super(key: key);

  @override
  State<BasketFullPage> createState() => _BasketFullPageState();
}

class _BasketFullPageState extends State<BasketFullPage> {
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final titleFontSize = isTablet ? 26.0 : 22.0;
    // final subtitleFontSize = isTablet ? 15.0 : 13.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.3,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.05),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Basket",
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            // Text(
            //   "View and manage your virtual basket.",
            //   style: TextStyle(
            //     color: Theme.of(context)
            //         .textTheme
            //         .bodyMedium
            //         ?.color
            //         ?.withOpacity(0.7),
            //     fontSize: subtitleFontSize,
            //     fontWeight: FontWeight.w400,
            //   ),
            // ),
          ],
        ),
      ),
      body: const PortfolioFragmentJournal(null),
    );
  }
}
