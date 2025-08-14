import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:optionxi/Main_Pages/act_tutor_detail_page.dart';

class TradingTutor {
  final int id;
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
  final bool verified;

  TradingTutor({
    required this.id,
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
    required this.verified,
  });

  factory TradingTutor.fromJson(Map<String, dynamic> json) {
    return TradingTutor(
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      students: json['students'] ?? 0,
      experience: json['experience'] ?? '',
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : [],
      bio: json['bio'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      achievements: json['achievements'] != null
          ? List<String>.from(json['achievements'])
          : [],
      verified: json['verified'] ?? false,
    );
  }
}

class TopTradingTutorsScreen extends StatefulWidget {
  @override
  _TopTradingTutorsScreenState createState() => _TopTradingTutorsScreenState();
}

class _TopTradingTutorsScreenState extends State<TopTradingTutorsScreen> {
  List<TradingTutor> tutors = [];

  @override
  void initState() {
    super.initState();
    _fetchTutors();
  }

  Future<void> _fetchTutors() async {
    try {
      final response = await Supabase.instance.client
          .from('tutorslist')
          .select('*')
          .eq('verified', true)
          .order('rating', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          tutors = response.map((json) => TradingTutor.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Silently handle errors - don't show error messages as requested
      print('Error fetching tutors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no tutors, don't show anything (no error, no loading)
    if (tutors.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: _buildHeader(context),
        ),
        SizedBox(height: 16),
        TutorCarousel(tutors: tutors),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Tutors',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Learn the basics from the masters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => const TopRecommendedStockPage(),
            //   ),
            // );
          },
          child: const Text('View All'),
        ),
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
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.tutors.isNotEmpty) {
      _pageController =
          PageController(viewportFraction: 0.85, initialPage: _currentPage);
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (widget.tutors.length > 1) {
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.tutors.isNotEmpty) {
      _pageController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tutors.isEmpty) {
      return SizedBox.shrink();
    }

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
        if (widget.tutors.length > 1) buildDotNavigation(context),
      ],
    );
  }

  Row buildDotNavigation(BuildContext context) {
    return Row(
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
                  tag: 'tutor_image_${tutor.id}',
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: tutor.image.isNotEmpty
                        ? NetworkImage(tutor.image)
                        : null,
                    child: tutor.image.isEmpty
                        ? Icon(Icons.person, size: 32)
                        : null,
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
