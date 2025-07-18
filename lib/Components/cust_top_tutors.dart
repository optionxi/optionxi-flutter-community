import 'dart:async';
import 'package:flutter/material.dart';
import 'package:optionxi/Main_Pages/act_tutor_detail_page.dart';

class TradingTutor {
  final String name;
  final String title;
  final String image;
  final String description;
  final double rating;
  final int students;
  final String experience;
  final List<String> specialties;
  final String bio;
  final double price;
  final List<String> achievements;

  TradingTutor({
    required this.name,
    required this.title,
    required this.image,
    required this.description,
    required this.rating,
    required this.students,
    required this.experience,
    required this.specialties,
    required this.bio,
    required this.price,
    required this.achievements,
  });
}

class TradingTutorsScreen extends StatelessWidget {
  final List<TradingTutor> tutors = [
    TradingTutor(
      name: "Sarah Chen",
      title: "Forex & Crypto Expert",
      image:
          "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop&crop=face",
      description:
          "Professional forex trader with 8+ years experience in currency markets",
      rating: 4.9,
      students: 1250,
      experience: "8+ years",
      specialties: [
        "Forex",
        "Cryptocurrency",
        "Technical Analysis",
        "Risk Management"
      ],
      bio:
          "Sarah is a seasoned forex trader who has been actively trading for over 8 years. She specializes in major currency pairs and has developed a unique scalping strategy that has helped hundreds of students achieve consistent profits. Her approach combines technical analysis with fundamental market understanding.",
      price: 99.99,
      achievements: [
        "Certified Financial Analyst (CFA)",
        "8+ years of profitable trading",
        "Featured in Trading Magazine",
        "Developed proprietary trading algorithm"
      ],
    ),
    TradingTutor(
      name: "Nikhil Mathew",
      title: "Stock Market Strategist",
      image:
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face",
      description:
          "Wall Street veteran specializing in equity trading and market analysis",
      rating: 4.8,
      students: 980,
      experience: "12+ years",
      specialties: ["Stocks", "Options", "Swing Trading", "Market Analysis"],
      bio:
          "Marcus brings over 12 years of Wall Street experience to his teaching. He has worked at major investment banks and now shares his knowledge with aspiring traders. His focus is on building sustainable trading strategies that work in both bull and bear markets.",
      price: 149.99,
      achievements: [
        "Former Goldman Sachs analyst",
        "12+ years Wall Street experience",
        "Author of 'Smart Trading Strategies'",
        "Managed 50M+ portfolio"
      ],
    ),
    TradingTutor(
      name: "Emily Watson",
      title: "Day Trading Specialist",
      image:
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face",
      description:
          "Expert day trader with proven track record in high-frequency trading",
      rating: 4.7,
      students: 750,
      experience: "6+ years",
      specialties: ["Day Trading", "Scalping", "Chart Patterns", "Psychology"],
      bio:
          "Emily is a full-time day trader who has mastered the art of quick, profitable trades. She focuses on teaching the psychological aspects of trading and how to maintain discipline in fast-paced market conditions. Her students learn to identify high-probability setups and manage risk effectively.",
      price: 79.99,
      achievements: [
        "6+ years of consistent day trading",
        "Developed 'Quick Strike' method",
        "Featured in Forbes",
        "90%+ win rate on scalping trades"
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Trading Tutors',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Learn from the best traders in the industry',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        TutorCarousel(tutors: tutors),
      ],
    );
  }
}

class TutorCarousel extends StatefulWidget {
  final List<TradingTutor> tutors;

  TutorCarousel({required this.tutors});

  @override
  _TutorCarouselState createState() => _TutorCarouselState();
}

class _TutorCarouselState extends State<TutorCarousel> {
  late final PageController _pageController;
  late final Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(viewportFraction: 0.85, initialPage: _currentPage);
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentPage < widget.tutors.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.tutors.length,
            itemBuilder: (context, index) {
              return TutorCard(
                tutor: widget.tutors[index],
                isActive: index == _currentPage,
              );
            },
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.tutors.length,
            (index) => AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TutorCard extends StatelessWidget {
  final TradingTutor tutor;
  final bool isActive;

  TutorCard({required this.tutor, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final double scale = isActive ? 1.0 : 0.9;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TutorDetailPage(tutor: tutor),
          ),
        );
      },
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: singleTutorCard(context),
      ),
    );
  }

  Card singleTutorCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'tutor_image_${tutor.name}',
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(tutor.image),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tutor.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        tutor.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              tutor.description,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Spacer(),
            Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 6),
                Text(
                  tutor.rating.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 20),
                Icon(Icons.people_alt_rounded,
                    color: Theme.of(context).colorScheme.secondary, size: 20),
                SizedBox(width: 6),
                Text(
                  '${tutor.students}+ students',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Profile',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
