import 'package:flutter/material.dart';
import 'package:bloc_structure/user_booking/data/models/review_model.dart';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

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
              Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
              const AppSizedBox(height: 12),
              AppText(
                text: "No reviews yet. Be the first to rate your experience!",
                textStyle: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 13),
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
      separatorBuilder: (_, __) => Divider(height: 48, color: Colors.grey.withOpacity(0.1)),
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
                color: Colors.grey.shade200,
                image: review.userImage.isNotEmpty
                    ? DecorationImage(image: NetworkImage(review.userImage), fit: BoxFit.cover)
                    : null,
              ),
              child: review.userImage.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
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
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
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
        if (review.mediaUrls.isNotEmpty) ...[
          const AppSizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: review.mediaUrls.length,
              itemBuilder: (context, index) {
                final url = review.mediaUrls[index];
                final isVideo = url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');
                return GestureDetector(
                  onTap: () => _showMediaGallery(context, review.mediaUrls, index),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: isVideo ? null : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      color: isVideo ? Colors.black87 : Colors.grey.shade200,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: isVideo ? const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40)) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _showMediaGallery(BuildContext context, List<String> urls, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: urls.length,
              itemBuilder: (context, index) {
                final url = urls[index];
                final isVideo = url.toLowerCase().contains('.mp4') || url.toLowerCase().contains('.mov');
                if (isVideo) {
                  return AppVideoPlayer(url: url);
                }
                return InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class AppVideoPlayer extends StatefulWidget {
  final String url;
  const AppVideoPlayer({required this.url, super.key});

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        // user specified play/pause/mute are implicitly covered by chewie controls
      );
      if (mounted) setState(() {});
    } catch (e) {
      print("Video Player Error: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(child: AppText(text: "Error playing video", textStyle: TextStyle(color: Colors.white)));
    }

    if (_chewieController == null || !_chewieController!.videoPlayerController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Chewie(controller: _chewieController!),
    );
  }
}
