import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/di/get_it/get_it.dart';
import 'package:bloc_structure/user_booking/domain/repositories/review_repository.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final String groundId;
  final String groundName;

  const AddReviewBottomSheet({required this.groundId, required this.groundName, super.key});

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final List<XFile> _mediaFiles = [];
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia() async {
    if (_mediaFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maximum 5 media files allowed")));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppSizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const AppSizedBox(height: 20),
            const AppText(text: "Add Media", textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const AppSizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: "Photo Camera",
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                    if (image != null) setState(() => _mediaFiles.add(image));
                  },
                ),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: "Photo Gallery",
                  onTap: () async {
                    Navigator.pop(context);
                    final images = await _picker.pickMultiImage(imageQuality: 70);
                    if (images.isNotEmpty) {
                      setState(() {
                        final availableSpace = 5 - _mediaFiles.length;
                        _mediaFiles.addAll(images.take(availableSpace));
                      });
                    }
                  },
                ),
              ],
            ),
            const AppSizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  icon: Icons.videocam_rounded,
                  label: "Video Camera",
                  onTap: () async {
                    Navigator.pop(context);
                    final video = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30));
                    if (video != null) setState(() => _mediaFiles.add(video));
                  },
                ),
                _buildPickerOption(
                  icon: Icons.video_library_rounded,
                  label: "Video Gallery",
                  onTap: () async {
                    Navigator.pop(context);
                    final video = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 30));
                    if (video != null) setState(() => _mediaFiles.add(video));
                  },
                ),
              ],
            ),
            const AppSizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryDarkGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primaryDarkGreen, size: 28),
          ),
          const AppSizedBox(height: 8),
          AppText(text: label, textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a rating")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final mediaBytesList = <Uint8List>[];
      final mediaTypes = <String>[];

      for (final file in _mediaFiles) {
        mediaBytesList.add(await file.readAsBytes());
        final path = file.path.toLowerCase();
        mediaTypes.add(path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.m4v') ? 'video' : 'image');
      }

      await getIt<ReviewRepository>().submitReview(
        userId: user.id,
        groundId: widget.groundId,
        rating: _rating,
        reviewText: _reviewController.text,
        mediaBytes: mediaBytesList,
        mediaTypes: mediaTypes,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
            const AppSizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(text: "Rate your experience", textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    AppText(text: widget.groundName, textStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey.withOpacity(0.1)),
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
                        index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: index < _rating ? Colors.amber : Colors.grey.withOpacity(0.3),
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
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const AppSizedBox(height: 24),
            const AppText(text: "Add Photos or Videos", textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const AppSizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickMedia,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), style: BorderStyle.none),
                      ),
                      child: Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...List.generate(_mediaFiles.length, (index) {
                    final file = _mediaFiles[index];
                    final isVideo = file.path.toLowerCase().endsWith('.mp4') || file.path.toLowerCase().endsWith('.mov');
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (!isVideo) {
                                _showZoomDialog(context, file.path, isFile: true);
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: isVideo
                                    ? null
                                    : DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover),
                                color: isVideo ? Colors.black87 : null,
                              ),
                              child: isVideo ? const Icon(Icons.play_circle_fill, color: Colors.white) : null,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _mediaFiles.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const AppText(
                        text: "Submit Review",
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showZoomDialog(BuildContext context, String path, {bool isFile = false}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isFile ? Image.file(File(path)) : Image.network(path),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
