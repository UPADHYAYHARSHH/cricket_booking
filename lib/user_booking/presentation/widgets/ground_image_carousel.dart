import 'package:flutter/material.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_network_image.dart';

class GroundImageCarousel extends StatefulWidget {
  final List<String> images;
  final String fallbackImageUrl;
  final double height;
  final BorderRadius? borderRadius;
  final bool showGradient;

  const GroundImageCarousel({
    super.key,
    required this.images,
    required this.fallbackImageUrl,
    this.height = 160,
    this.borderRadius,
    this.showGradient = true,
  });

  @override
  State<GroundImageCarousel> createState() => _GroundImageCarouselState();
}

class _GroundImageCarouselState extends State<GroundImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.images.isNotEmpty 
        ? widget.images 
        : [widget.fallbackImageUrl.isNotEmpty ? widget.fallbackImageUrl : "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e"];

    return Stack(
      children: [
        // Image Slider
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: displayImages.length,
              itemBuilder: (context, index) {
                return AppNetworkImage(
                  imageUrl: displayImages[index],
                  height: widget.height,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        
        // Dark Gradient Overlay for better visibility of indicator and badges
        if (widget.showGradient)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.zero,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

        // Center Dot Indicator
        if (displayImages.length > 1)
          Positioned(
            bottom: 12,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                displayImages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: _currentPage == index ? 16 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      if (_currentPage == index)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
