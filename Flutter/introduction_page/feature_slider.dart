
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class FeatureSlider extends StatefulWidget {
  const FeatureSlider({super.key});

  @override
  State<FeatureSlider> createState() => _FeatureSliderState();
}


class _FeatureSliderState extends State<FeatureSlider> {
  final PageController _cardController = PageController();
  int _currentCard = 0;
  Timer? _sliderTimer;

  final List<Map<String, String>> cardData = [
    {
      "title": "AI Workout Plans",
      "desc": "Personalized routines in seconds 💪",
    },
    {
      "title": "Smart Diets",
      "desc": "Meal plans that respect your culture 🍽️",
    },
    {
      "title": "Calendar Sync",
      "desc": "Never miss a workout again 📅",
    },
  ];

  void startAutoSlide() {
    _sliderTimer?.cancel(); // Cancel any existing timer
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _currentCard = (_currentCard + 1) % cardData.length;
        _cardController.animateToPage(
          _currentCard,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    });
  }

  @override
  void initState() {
    super.initState();
    startAutoSlide();
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _cardController,
            onPageChanged: (index) {
              _currentCard = index;
            },
            itemCount: cardData.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardData[index]["title"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cardData[index]["desc"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: _cardController,
          count: cardData.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: Colors.white,
            dotColor: Colors.white38,
            dotHeight: 6,
            dotWidth: 6,
          ),
        ),
      ],
    );
  }
}

