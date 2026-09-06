import 'package:flutter/material.dart';
import 'package:turfpro/user_booking/data/models/review_model.dart';
import 'package:turfpro/user_booking/presentation/widgets/slot_selection_widgets.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro/common/widgets/discover_app_bar.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = ModalRoute.of(context)?.settings.arguments as List<ReviewModel>? ?? [];
    
    final averageRating = reviews.isEmpty ? 0.0 : reviews.fold(0.0, (sum, review) => sum + review.rating) / reviews.length;

    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          text: "All Reviews",
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: const DiscoverAppBarBackground(),
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      AppText(
                        text: averageRating.toStringAsFixed(1),
                        textStyle: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.floor() 
                              ? Icons.star_rounded 
                              : (index < averageRating ? Icons.star_half_rounded : Icons.star_border_rounded),
                            color: AppColors.goldenYellow,
                            size: 24,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        text: "Based on ${reviews.length} reviews",
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SlotSelectionWidgets.buildReviewCard(context, reviews[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
