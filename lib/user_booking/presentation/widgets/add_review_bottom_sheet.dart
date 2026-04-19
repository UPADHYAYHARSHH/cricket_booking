import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/di/get_it/get_it.dart';
import 'package:bloc_structure/user_booking/domain/repositories/review_repository.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final String groundId;
  final String groundName;

  const AddReviewBottomSheet(
      {required this.groundId, required this.groundName, super.key});

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;



  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please provide a rating")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      await getIt<ReviewRepository>().submitReview(
        userId: user.id,
        groundId: widget.groundId,
        rating: _rating,
        reviewText: _reviewController.text,
        mediaBytes: [],
        mediaTypes: [],
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Review submitted successfully!"),
            backgroundColor: AppColors.primaryDarkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10)))),
            const AppSizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                        text: "Rate your experience",
                        textStyle: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    AppText(
                        text: widget.groundName,
                        textStyle: TextStyle(
                            fontSize: 14,
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                ),
              ],
            ),
            const AppSizedBox(height: 32),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: index < _rating
                            ? AppColors.goldenYellow
                            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        size: 48,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const AppSizedBox(height: 32),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write your review here...",
                hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const AppSizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const AppText(
                        text: "Submit Review",
                        textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
