import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContributorsPage extends StatefulWidget {
  const ContributorsPage({super.key});

  @override
  State<ContributorsPage> createState() => _ContributorsPageState();
}

class _ContributorsPageState extends State<ContributorsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Main contributors with detailed cards
  final List<Contributor> contributors = [
    Contributor(
      name: "Alex Johnson",
      role: "Lead Developer",
      description:
          "Architected the core framework and led the development team",
      imageUrl:
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      color: Colors.blue,
      socialUrl: "https://github.com/alexjohnson",
    ),
    Contributor(
      name: "Sarah Chen",
      role: "UI/UX Designer",
      description: "Crafted the beautiful user interface and user experience",
      imageUrl:
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      color: Colors.purple,
      socialUrl: "https://dribbble.com/sarahchen",
    ),
    Contributor(
      name: "Mike Rodriguez",
      role: "Backend Engineer",
      description: "Built the robust backend infrastructure and APIs",
      imageUrl:
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      color: Colors.green,
      socialUrl: "https://github.com/mikerodriguez",
    ),
    Contributor(
      name: "Emma Wilson",
      role: "QA Engineer",
      description:
          "Ensured quality and reliability through comprehensive testing",
      imageUrl:
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      color: Colors.orange,
      socialUrl: "https://linkedin.com/in/emmawilson",
    ),
  ];

  // Supporters with just avatar and social link
  final List<Supporter> supporters = [
    Supporter(
        name: "John Doe",
        imageUrl:
            "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/johndoe"),
    Supporter(
        name: "Jane Smith",
        imageUrl:
            "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/janesmith"),
    Supporter(
        name: "Bob Wilson",
        imageUrl:
            "https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/bobwilson"),
    Supporter(
        name: "Alice Brown",
        imageUrl:
            "https://images.unsplash.com/photo-1607746882042-944635dfe10e?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/alicebrown"),
    Supporter(
        name: "Charlie Davis",
        imageUrl:
            "https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/charliedavis"),
    Supporter(
        name: "Diana Green",
        imageUrl:
            "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/dianagreen"),
    Supporter(
        name: "Frank Miller",
        imageUrl:
            "https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/frankmiller"),
    Supporter(
        name: "Grace Lee",
        imageUrl:
            "https://images.unsplash.com/photo-1619895862022-09114b41f16f?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/gracelee"),
    Supporter(
        name: "Henry Taylor",
        imageUrl:
            "https://images.unsplash.com/photo-1552058544-f2b08422138a?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/henrytaylor"),
    Supporter(
        name: "Ivy Chen",
        imageUrl:
            "https://images.unsplash.com/photo-1488508872907-592763824245?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/ivychen"),
    Supporter(
        name: "Jack White",
        imageUrl:
            "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/jackwhite"),
    Supporter(
        name: "Kelly Blue",
        imageUrl:
            "https://images.unsplash.com/photo-1634896941598-b6b500a502a7?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/kellyblue"),
    Supporter(
        name: "Leo Black",
        imageUrl:
            "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/leoblack"),
    Supporter(
        name: "Mia Red",
        imageUrl:
            "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/miared"),
    Supporter(
        name: "Noah Gold",
        imageUrl:
            "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/noahgold"),
    Supporter(
        name: "Olivia Silver",
        imageUrl:
            "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/oliviasilver"),
    Supporter(
        name: "Mia Red",
        imageUrl:
            "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/miared"),
    Supporter(
        name: "Noah Gold",
        imageUrl:
            "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/noahgold"),
    Supporter(
        name: "Olivia Silver",
        imageUrl:
            "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&crop=face",
        socialUrl: "https://github.com/oliviasilver"),
  ];

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFFf8f9fa),
                    const Color(0xFFe9ecef),
                    const Color(0xFFdee2e6),
                  ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Sticky shrinking header
              _buildSliverAppBar(isDark),
              // Contributors section
              _buildContributorsSection(isDark),
              // Supporters section
              _buildSupportersSection(isDark),
              // Footer
              _buildFooter(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      stretch: true,
      // backgroundColor: Colors.transparent,
      elevation: 10,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: isDark ? Colors.amber : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Hall of Fame',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.auto_awesome,
              color: isDark ? Colors.amber : Colors.orange,
              size: 20,
            ),
          ],
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildContributorsSection(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Supporters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Amazing people who helped and supported the project',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            // const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contributors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildContributorCard(
                    contributors[index], isDark, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportersSection(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Supporters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Amazing people who helped and supported the project',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            _buildSupportersGrid(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildContributorCard(
      Contributor contributor, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.grey[850]?.withOpacity(0.7) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: contributor.color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Profile avatar with glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: contributor.color.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: contributor.color.withOpacity(0.1),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: contributor.color,
                          backgroundImage: NetworkImage(contributor.imageUrl),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: contributor.color,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Name and role
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contributor.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              // Role badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: contributor.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  contributor.role,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: contributor.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Description
                          Text(
                            contributor.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Social link button
                    if (contributor.socialUrl.isNotEmpty)
                      InkWell(
                        onTap: () => _launchUrl(contributor.socialUrl),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: contributor.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: contributor.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.open_in_new,
                            size: 18,
                            color: contributor.color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportersGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[900]?.withOpacity(0.5)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: supporters.length,
        itemBuilder: (context, index) {
          return _buildSupporterAvatar(supporters[index], isDark, index);
        },
      ),
    );
  }

  Widget _buildSupporterAvatar(Supporter supporter, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1000 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Tooltip(
            message: supporter.name,
            child: InkWell(
              onTap: () => _launchUrl(supporter.socialUrl),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Image.network(
                    supporter.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Made with love by an amazing community',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You found the secret page! 🎉',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.amber.shade300 : Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class Contributor {
  final String name;
  final String role;
  final String description;
  final String imageUrl;
  final Color color;
  final String socialUrl;

  Contributor({
    required this.name,
    required this.role,
    required this.description,
    required this.imageUrl,
    required this.color,
    required this.socialUrl,
  });
}

class Supporter {
  final String name;
  final String imageUrl;
  final String socialUrl;

  Supporter({
    required this.name,
    required this.imageUrl,
    required this.socialUrl,
  });
}
