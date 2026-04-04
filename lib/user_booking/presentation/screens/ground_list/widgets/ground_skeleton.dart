import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GroundSkeleton extends StatelessWidget {
  const GroundSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Image Placeholder
            Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Name Placeholder
                  Container(
                    width: 150,
                    height: 16,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 8),

                  /// Address Placeholder
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Container(
                    width: 200,
                    height: 12,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Price Placeholder
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),

                      /// Button Placeholder
                      Container(
                        width: 70,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
