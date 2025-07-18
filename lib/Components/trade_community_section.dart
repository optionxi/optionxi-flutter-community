import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/act_tradingideas.dart';

final List<GroupData> yourGroups = [
  GroupData(
    name: "Nifty and Bank",
    memberCount: 11,
    activityCount: "110+ trades",
    color: Color(0xFF2962FF),
    isLeader: true,
  ),
  GroupData(
    name: "Nifty 50 Stocks",
    memberCount: 8,
    activityCount: "130+ trades",
    color: Color(0xFF6200EA),
    isLeader: true,
  ),
  GroupData(
    name: "Nifty 200 Stocks",
    memberCount: 8,
    activityCount: "130+ trades",
    color: Color(0xFF2962FF),
    isLeader: true,
  ),
  GroupData(
    name: "FnO Stocks",
    memberCount: 8,
    activityCount: "130+ trades",
    color: Color(0xFF6200EA),
    isLeader: true,
  ),
];

class GroupData {
  final String name;
  final int memberCount;
  final String activityCount;
  final Color color;
  final bool isLeader;

  GroupData({
    required this.name,
    required this.memberCount,
    required this.activityCount,
    required this.color,
    required this.isLeader,
  });
}

Widget buildTradingIdeas(
    BuildContext context, AnimationController _controller) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Trading Ideas",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => TradingIdeasPage()));
            },
            child: Text(
              "See All",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 200,
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: yourGroups.length,
          itemBuilder: (context, index) {
            return InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TradingIdeasPage()));
                },
                child: _buildGroupCard(yourGroups[index], index, _controller));
          },
        ),
      ),
    ],
  );
}

Widget _buildGroupCard(
    GroupData group, int index, AnimationController _controller) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: Offset(0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.1 * index, 0.1 * index + 0.2, curve: Curves.easeOut),
      ),
    ),
    child: Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [group.color, group.color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: group.color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (group.isLeader)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 4),
                  Text(
                    "AI Alerts",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 24,
                child: Stack(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        left: i * 20.0,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: group.color, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                size: 16, color: Colors.black87),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                "+${group.memberCount}",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.yellow, size: 16),
                Icon(Icons.star, color: Colors.yellow, size: 16),
                Icon(Icons.star, color: Colors.yellow, size: 16),
                Icon(Icons.star, color: Colors.yellow, size: 16),

                // Text(
                //   group.activityCount,
                //   style: TextStyle(color: Colors.white),
                // ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
