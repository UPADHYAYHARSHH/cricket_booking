import 'package:flutter/material.dart';
import 'package:turfpro/user_booking/data/models/review_model.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:intl/intl.dart';

class ReviewList extends StatelessWidget {
  final List<ReviewModel> reviews;
  const ReviewList({required this.reviews, super.key});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
              const AppSizedBox(height: 12),
              AppText(
                text: "No reviews yet. Be the first to rate your experience!",
                textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => Divider(height: 48, color: Theme.of(context).dividerColor.withOpacity(0.5)),
      itemBuilder: (context, index) => ReviewCard(review: reviews[index]),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const ReviewCard({required this.review, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.05),
                image: review.userImage.isNotEmpty
                    ? DecorationImage(image: NetworkImage(review.userImage), fit: BoxFit.cover)
                    : null,
              ),
              child: review.userImage.isEmpty ? Icon(Icons.person, color: theme.colorScheme.onSurface.withOpacity(0.3)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: review.userName,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  AppText(
                    text: DateFormat('d MMM yyyy').format(review.createdAt),
                    textStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldenYellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                   Icon(Icons.star_rounded, color: AppColors.goldenYellow, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13, 
                      color: theme.brightness == Brightness.dark 
                          ? AppColors.goldenYellow 
                          : const Color(0xFF856404)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const AppSizedBox(height: 16),
        if (review.reviewText.isNotEmpty)
          AppText(
            text: review.reviewText,
            textStyle: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),

      ],
    );
  }
}


