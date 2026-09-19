import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turfpro/common/constants/colors.dart';
import '../../../di/get_it/get_it.dart';
import '../../blocs/profile/profile_cubit.dart';

enum CharacterPose { crossedArms, batsman, bowler, allRounder }
enum AvatarGender { male, female }

class SkinTone {
  final String name;
  final Color baseColor;
  final Color shadowColor;
  final Color highlightColor;

  const SkinTone({
    required this.name,
    required this.baseColor,
    required this.shadowColor,
    required this.highlightColor,
  });
}

const List<SkinTone> kSkinTones = [
  SkinTone(
    name: "Fair",
    baseColor: Color(0xFFFFDFC4),
    shadowColor: Color(0xFFE8B997),
    highlightColor: Color(0xFFFFF3E8),
  ),
  SkinTone(
    name: "Peach",
    baseColor: Color(0xFFF0C08A),
    shadowColor: Color(0xFFD49E65),
    highlightColor: Color(0xFFFBE4C8),
  ),
  SkinTone(
    name: "Golden",
    baseColor: Color(0xFFCE9662),
    shadowColor: Color(0xFFA8703E),
    highlightColor: Color(0xFFE4BA8E),
  ),
  SkinTone(
    name: "Caramel",
    baseColor: Color(0xFF9E653A),
    shadowColor: Color(0xFF7A4720),
    highlightColor: Color(0xFFBD8559),
  ),
  SkinTone(
    name: "Deep",
    baseColor: Color(0xFF6B4226),
    shadowColor: Color(0xFF4A2B15),
    highlightColor: Color(0xFF8B5A37),
  ),
];

class OutfitStyle {
  final String name;
  final List<Color> shirtColors;
  final Color collarColor;
  final Color stripeColor;
  final String brandText;

  const OutfitStyle({
    required this.name,
    required this.shirtColors,
    required this.collarColor,
    required this.stripeColor,
    this.brandText = "TurfPro",
  });
}

const List<OutfitStyle> kOutfitStyles = [
  OutfitStyle(
    name: "Snap Grey Tee",
    shirtColors: [Color(0xFFE0E0E0), Color(0xFFCCCCCC)],
    collarColor: Color(0xFF9E9E9E),
    stripeColor: Color(0xFF757575),
    brandText: "Calvin Klein",
  ),
  OutfitStyle(
    name: "Emerald Cricket",
    shirtColors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
    collarColor: Color(0xFFFFD700),
    stripeColor: Color(0xFFFFD700),
    brandText: "TURF PRO",
  ),
  OutfitStyle(
    name: "India Sky Blue",
    shirtColors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
    collarColor: Color(0xFFFF9933),
    stripeColor: Color(0xFFFF9933),
    brandText: "INDIA",
  ),
  OutfitStyle(
    name: "Midnight Gold",
    shirtColors: [Color(0xFF262626), Color(0xFF141414)],
    collarColor: Color(0xFFFFC107),
    stripeColor: Color(0xFFFFC107),
    brandText: "ROYALS",
  ),
  OutfitStyle(
    name: "Royal Flame",
    shirtColors: [Color(0xFFD32F2F), Color(0xFF8E0000)],
    collarColor: Color(0xFFFFC107),
    stripeColor: Color(0xFFFFFFFF),
    brandText: "CHALLENGERS",
  ),
];

class PlayerAvatarScreen extends StatefulWidget {
  const PlayerAvatarScreen({super.key});

  @override
  State<PlayerAvatarScreen> createState() => _PlayerAvatarScreenState();
}

class _PlayerAvatarScreenState extends State<PlayerAvatarScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _avatarCaptureKey = GlobalKey();

  // Character Attributes matching Snapchat 3D Bitmoji
  AvatarGender _gender = AvatarGender.male;
  CharacterPose _pose = CharacterPose.crossedArms;
  int _skinToneIndex = 1;
  int _hairColorIndex = 0;
  int _outfitIndex = 0;
  String _jerseyNumber = "07";
  bool _hasSunglasses = true;
  bool _hasHeadphones = true;
  bool _hasBackpack = true;
  bool _hasBeard = true;
  int _pantsColorIndex = 0; // 0: Black Tracks, 1: Cricket Whites, 2: Navy Joggers
  int _shoesColorIndex = 0; // 0: Dunk Panda, 1: Clean White, 2: Turf Green

  // Interactive 3D Turntable Angle Controls
  double _rotateY = 0.0; // Horizontal 3D rotation (-pi to +pi)
  double _rotateX = 0.0; // Vertical pitch (-0.2 to 0.2)
  bool _autoRotate = false;

  // Real Animation Engine (Idle Breathing, Blinking)
  late AnimationController _idleAnimController;
  Timer? _blinkTimer;
  bool _isBlinking = false;

  // UI Drawer State
  int _activeCategory = 0; // 0: Try New Look, 1: Roles, 2: Poses, 3: Avatar
  bool _isSaving = false;

  final List<Color> _hairColors = [
    const Color(0xFF1F1B18), // Jet Black
    const Color(0xFF4A2E1B), // Espresso Brown
    const Color(0xFF8D5B34), // Warm Chestnut
    const Color(0xFFD4A373), // Dirty Blonde
    const Color(0xFFE5E5E5), // Platinum Silver
  ];

  final List<Color> _pantsColors = [
    const Color(0xFF212121), // Charcoal Track Pants
    const Color(0xFFEEEEEE), // Cricket Whites
    const Color(0xFF1A237E), // Navy Joggers
  ];

  @override
  void initState() {
    super.initState();

    // Idle breathing animation loop (continuous natural living motion)
    _idleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _idleAnimController.addListener(() {
      if (_autoRotate) {
        setState(() {
          _rotateY += 0.012;
          if (_rotateY > math.pi) _rotateY -= 2 * math.pi;
        });
      } else {
        setState(() {}); // Repaint idle breathing
      }
    });

    // Natural blinking loop every 3.5 seconds
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3600), (timer) {
      if (mounted) {
        setState(() => _isBlinking = true);
        Future.delayed(const Duration(milliseconds: 160), () {
          if (mounted) setState(() => _isBlinking = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _idleAnimController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _syncGenderFromProfile(ProfileState state) {
    if (state.gender != null) {
      final g = state.gender!.toLowerCase();
      if (g == 'female' && _gender != AvatarGender.female) {
        setState(() => _gender = AvatarGender.female);
      } else if (g == 'male' && _gender != AvatarGender.male) {
        setState(() => _gender = AvatarGender.male);
      }
    }
  }

  Future<void> _captureAndSaveAvatar(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final boundary = _avatarCaptureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Render boundary not found");
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }

      final bytes = byteData.buffer.asUint8List();
      final xFile = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'snapchat_cricket_avatar_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (!context.mounted) return;
      await context.read<ProfileCubit>().uploadImage(xFile);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ 3D Avatar set as your profile picture!"),
          backgroundColor: AppColors.primaryDarkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not save avatar: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..loadProfile(),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          _syncGenderFromProfile(state);
        },
        builder: (context, profileState) {
          final playerName = profileState.name?.isNotEmpty == true
              ? profileState.name!
              : "Player";

          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final bottomInset = MediaQuery.of(context).padding.bottom;
          final bottomPadding = math.max(16.0, bottomInset + 8.0);

          return Scaffold(
            backgroundColor: const Color(0xFFE9E5DE), // Warm room wall tone
            body: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final screenWidth = constraints.maxWidth;
                  // Dynamic bottom drawer height respecting safe area padding
                  final bottomDrawerHeight = 230.0 + bottomPadding;
                  final stageHeight = screenHeight - bottomDrawerHeight;

                  return Stack(
                    children: [
                      // 1. 3D ROOM SCENE & FULL BODY CHARACTER (HEAD TO SHOES 100% VISIBLE)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: screenHeight,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _autoRotate = false;
                              _rotateY += details.delta.dx * 0.015;
                              if (_rotateY > math.pi) _rotateY -= 2 * math.pi;
                              if (_rotateY < -math.pi) _rotateY += 2 * math.pi;
                            });
                          },
                          onVerticalDragUpdate: (details) {
                            setState(() {
                              _rotateX = (_rotateX - details.delta.dy * 0.008)
                                  .clamp(-0.2, 0.2);
                            });
                          },
                          child: RepaintBoundary(
                            key: _avatarCaptureKey,
                            child: CustomPaint(
                              painter: _SnapchatFullBodyAvatarPainter(
                                gender: _gender,
                                pose: _pose,
                                skinTone: kSkinTones[_skinToneIndex],
                                hairColor: _hairColors[_hairColorIndex],
                                outfit: kOutfitStyles[_outfitIndex],
                                pantsColor: _pantsColors[_pantsColorIndex],
                                shoesColorIndex: _shoesColorIndex,
                                squadNumber: _jerseyNumber,
                                hasSunglasses: _hasSunglasses,
                                hasHeadphones: _hasHeadphones,
                                hasBackpack: _hasBackpack,
                                hasBeard:
                                    _gender == AvatarGender.male && _hasBeard,
                                rotateY: _rotateY,
                                rotateX: _rotateX,
                                idleBreath: _idleAnimController.value,
                                isBlinking: _isBlinking,
                                stageHeight: stageHeight,
                                screenWidth: screenWidth,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),

                      // 2. TOP FLOATING SNAPCHAT APP BAR
                      Positioned(
                        top: 10,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Close Button (X)
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),

                            // Center Share Pill
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Avatar link copied!"),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFFC00), // Snapchat yellow
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.qr_code_2,
                                        size: 13,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "Share",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right Save / Snap Pill
                            GestureDetector(
                              onTap: () => _captureAndSaveAvatar(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    _isSaving
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "Snap",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. 3D TURNTABLE CONTROLS (Right side floating icons)
                      Positioned(
                        right: 16,
                        top: 70,
                        child: Column(
                          children: [
                            // Auto-spin toggle
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _autoRotate = !_autoRotate);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _autoRotate
                                      ? AppColors.primaryDarkGreen
                                      : Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.sync_rounded,
                                  size: 19,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Reset Front View
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _rotateY = 0.0;
                                  _rotateX = 0.0;
                                });
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.accessibility_new_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. BOTTOM SNAPCHAT DRAWER & FLOATING CATEGORY BUTTONS
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Floating Category Circles
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildFloatingCategoryIcon(
                                      0, Icons.checkroom_rounded, "Fashion"),
                                  _buildFloatingCategoryIcon(
                                      1, Icons.sports_cricket_rounded, "Roles"),
                                  _buildFloatingCategoryIcon(
                                      2, Icons.sports_gymnastics, "Poses"),
                                  _buildFloatingCategoryIcon(
                                      3,
                                      Icons.face_retouching_natural,
                                      "Avatar"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // "Try a new look" Bottom Card Container
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: isDark ? 0.35 : 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Grab handle bar
                                  Center(
                                    child: Container(
                                      width: 36,
                                      height: 3.5,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.25)
                                            : Colors.black.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Header Title
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _getCategoryTitle(),
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      Text(
                                        playerName,
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.55),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Dynamic Card Content based on category
                                  _buildDrawerContent(),

                                  const SizedBox(height: 14),

                                  // Big "Set as Profile Photo" button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _captureAndSaveAvatar(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryDarkGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded,
                                                    size: 18),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    "Set as Profile Photo",
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCategoryTitle() {
    switch (_activeCategory) {
      case 0:
        return "Try a new look";
      case 1:
        return "Cricket Roles";
      case 2:
        return "Character Poses";
      case 3:
        return "Avatar & Hair";
      default:
        return "Customization";
    }
  }

  Widget _buildFloatingCategoryIcon(int index, IconData icon, String label) {
    final isSelected = _activeCategory == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeCategory = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryDarkGreen
                  : (isDark
                      ? Colors.black.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.9)),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.1),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primaryDarkGreen
                  : (isDark ? Colors.white : Colors.black87),
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerContent() {
    switch (_activeCategory) {
      case 0:
        return _buildTryNewLookRow();
      case 1:
        return _buildCricketRolesRow();
      case 2:
        return _buildPosesRow();
      case 3:
        return _buildAvatarAttributesRow();
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. Try A New Look (Exact Cards from User's Screenshot)
  Widget _buildTryNewLookRow() {
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Card 1: Sunglasses Toggle
          _buildItemCard(
            title: "Sunglasses",
            subtitle: _hasSunglasses ? "Equipped" : "None",
            icon: Icons.dark_mode_outlined,
            isSelected: _hasSunglasses,
            onTap: () => setState(() => _hasSunglasses = !_hasSunglasses),
          ),
          const SizedBox(width: 8),

          // Card 2: Over-Ear Headphones Toggle
          _buildItemCard(
            title: "Headphones",
            subtitle: _hasHeadphones ? "AirPods Max" : "None",
            icon: Icons.headphones_rounded,
            isSelected: _hasHeadphones,
            onTap: () => setState(() => _hasHeadphones = !_hasHeadphones),
          ),
          const SizedBox(width: 8),

          // Card 3: Sports Backpack / Kitbag Toggle
          _buildItemCard(
            title: "Sports Bag",
            subtitle: _hasBackpack ? "Equipped" : "None",
            icon: Icons.backpack_outlined,
            isSelected: _hasBackpack,
            onTap: () => setState(() => _hasBackpack = !_hasBackpack),
          ),
          const SizedBox(width: 8),

          // Card 4: Outfit Toggle
          _buildItemCard(
            title: "Outfit",
            subtitle: kOutfitStyles[_outfitIndex].name,
            icon: Icons.checkroom_rounded,
            isSelected: true,
            onTap: () {
              setState(() {
                _outfitIndex = (_outfitIndex + 1) % kOutfitStyles.length;
              });
            },
          ),
          const SizedBox(width: 8),

          // Card 5: Track Pants
          _buildItemCard(
            title: "Pants",
            subtitle: _pantsColorIndex == 0
                ? "Black Tracks"
                : (_pantsColorIndex == 1 ? "Cricket Whites" : "Navy Joggers"),
            icon: Icons.airline_seat_legroom_extra,
            isSelected: true,
            onTap: () {
              setState(() {
                _pantsColorIndex = (_pantsColorIndex + 1) % _pantsColors.length;
              });
            },
          ),
          const SizedBox(width: 8),

          // Card 6: Sneakers
          _buildItemCard(
            title: "Sneakers",
            subtitle: _shoesColorIndex == 0
                ? "Dunk Panda"
                : (_shoesColorIndex == 1 ? "White Court" : "Neon Spikes"),
            icon: Icons.roller_skating_outlined,
            isSelected: true,
            onTap: () {
              setState(() {
                _shoesColorIndex = (_shoesColorIndex + 1) % 3;
              });
            },
          ),
        ],
      ),
    );
  }

  // 2. Cricket Roles Row
  Widget _buildCricketRolesRow() {
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildItemCard(
            title: "Batsman",
            subtitle: "Bat & Gloves 🏏",
            icon: Icons.sports_cricket,
            isSelected: _pose == CharacterPose.batsman,
            onTap: () => setState(() => _pose = CharacterPose.batsman),
          ),
          const SizedBox(width: 8),
          _buildItemCard(
            title: "Bowler",
            subtitle: "Seam Ball ⚡",
            icon: Icons.sports_baseball,
            isSelected: _pose == CharacterPose.bowler,
            onTap: () => setState(() => _pose = CharacterPose.bowler),
          ),
          const SizedBox(width: 8),
          _buildItemCard(
            title: "All-Rounder",
            subtitle: "Dual Gear ⭐",
            icon: Icons.stars_rounded,
            isSelected: _pose == CharacterPose.allRounder,
            onTap: () => setState(() => _pose = CharacterPose.allRounder),
          ),
          const SizedBox(width: 8),
          _buildItemCard(
            title: "Squad Number",
            subtitle: "#$_jerseyNumber",
            icon: Icons.format_list_numbered,
            isSelected: true,
            onTap: () => _showSquadNumberPicker(),
          ),
        ],
      ),
    );
  }

  // 3. Poses Row
  Widget _buildPosesRow() {
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildItemCard(
            title: "Crossed Arms",
            subtitle: "Snapchat Chill",
            icon: Icons.accessibility_new,
            isSelected: _pose == CharacterPose.crossedArms,
            onTap: () => setState(() => _pose = CharacterPose.crossedArms),
          ),
          const SizedBox(width: 8),
          _buildItemCard(
            title: "Batsman Stance",
            subtitle: "Shoulder Bat",
            icon: Icons.sports_cricket,
            isSelected: _pose == CharacterPose.batsman,
            onTap: () => setState(() => _pose = CharacterPose.batsman),
          ),
          const SizedBox(width: 8),
          _buildItemCard(
            title: "Bowler Stance",
            subtitle: "Leather Ball Ready",
            icon: Icons.sports_baseball,
            isSelected: _pose == CharacterPose.bowler,
            onTap: () => setState(() => _pose = CharacterPose.bowler),
          ),
          const SizedBox(width: 8),
          _buildItemCard(
            title: "All-Rounder",
            subtitle: "Complete Kit",
            icon: Icons.shield,
            isSelected: _pose == CharacterPose.allRounder,
            onTap: () => setState(() => _pose = CharacterPose.allRounder),
          ),
        ],
      ),
    );
  }

  // 4. Avatar Attributes (Gender, Skin Tone, Hair, Beard)
  Widget _buildAvatarAttributesRow() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Gender Toggle
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = AvatarGender.male),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: _gender == AvatarGender.male
                        ? AppColors.primaryDarkGreen.withValues(alpha: 0.25)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _gender == AvatarGender.male
                          ? AppColors.primaryDarkGreen
                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Male ♂",
                      style: TextStyle(
                          color: _gender == AvatarGender.male
                              ? AppColors.primaryDarkGreen
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = AvatarGender.female),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: _gender == AvatarGender.female
                        ? AppColors.primaryDarkGreen.withValues(alpha: 0.25)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _gender == AvatarGender.female
                          ? AppColors.primaryDarkGreen
                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Female ♀",
                      style: TextStyle(
                          color: _gender == AvatarGender.female
                              ? AppColors.primaryDarkGreen
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
            if (_gender == AvatarGender.male) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _hasBeard = !_hasBeard),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _hasBeard
                        ? AppColors.primaryDarkGreen.withValues(alpha: 0.25)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _hasBeard
                          ? AppColors.primaryDarkGreen
                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Text(
                    "Beard 🧔",
                    style: TextStyle(
                        color: _hasBeard
                            ? AppColors.primaryDarkGreen
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Skin tone circles
        Row(
          children: [
            Text(
              "Skin: ",
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11),
            ),
            const SizedBox(width: 4),
            ...List.generate(kSkinTones.length, (idx) {
              final isSel = _skinToneIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _skinToneIndex = idx),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: kSkinTones[idx].baseColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel
                          ? (isDark ? Colors.white : AppColors.primaryDarkGreen)
                          : Colors.transparent,
                      width: 2.2,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text(
              "Hair: ",
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11),
            ),
            const SizedBox(width: 4),
            ...List.generate(_hairColors.length, (idx) {
              final isSel = _hairColorIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _hairColorIndex = idx),
                child: Container(
                  margin: const EdgeInsets.only(right: 5),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _hairColors[idx],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSel ? AppColors.primaryDarkGreen : (isDark ? Colors.white24 : Colors.black26),
                      width: 1.8,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // Snapchat-style item card
  Widget _buildItemCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 82,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDarkGreen.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark ? const Color(0xFF1E1E1E) : theme.scaffoldBackgroundColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDarkGreen
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.primaryDarkGreen
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1.5),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryDarkGreen
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSquadNumberPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final nums = ["07", "18", "45", "10", "99", "01", "24", "12"];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Squad Number",
                style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: nums.map((n) {
                  final isSel = _jerseyNumber == n;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _jerseyNumber = n);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primaryDarkGreen
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel
                              ? (isDark ? Colors.white : AppColors.primaryDarkGreen)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "#$n",
                          style: TextStyle(
                            color: isSel
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D ROOM SCENE & FULL BODY ANATOMICAL REAL ANIMATED BITMOJI PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _SnapchatFullBodyAvatarPainter extends CustomPainter {
  final AvatarGender gender;
  final CharacterPose pose;
  final SkinTone skinTone;
  final Color hairColor;
  final OutfitStyle outfit;
  final Color pantsColor;
  final int shoesColorIndex;
  final String squadNumber;
  final bool hasSunglasses;
  final bool hasHeadphones;
  final bool hasBackpack;
  final bool hasBeard;
  final double rotateY;
  final double rotateX;
  final double idleBreath; // 0.0 to 1.0 sine wave
  final bool isBlinking;
  final double stageHeight;
  final double screenWidth;

  _SnapchatFullBodyAvatarPainter({
    required this.gender,
    required this.pose,
    required this.skinTone,
    required this.hairColor,
    required this.outfit,
    required this.pantsColor,
    required this.shoesColorIndex,
    required this.squadNumber,
    required this.hasSunglasses,
    required this.hasHeadphones,
    required this.hasBackpack,
    required this.hasBeard,
    required this.rotateY,
    required this.rotateX,
    required this.idleBreath,
    required this.isBlinking,
    required this.stageHeight,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. DRAW SNAPCHAT ROOM BACKGROUND SCENE
    _drawRoomScene(canvas, size);

    // 2. STAGE CALCULATIONS & DYNAMIC SCALE
    // Available vertical height for character: from topBar (y = 55) to ground
    final groundY = stageHeight - 16;
    final groundX = size.width * 0.5;

    // The canonical character height from top of hair to bottom of sneakers is ~385px
    const canonicalCharHeight = 385.0;
    final availableHeight = groundY - 60.0;
    final scale = (availableHeight / canonicalCharHeight).clamp(0.72, 1.05);

    // 3D Parallax Offsets
    final breathOffset = math.sin(idleBreath * 2 * math.pi) * 3.0;
    final parallaxX = rotateY * 24;
    final parallaxY = rotateX * 16;

    canvas.save();
    // Scale around ground center so feet always stay anchored on the room floor!
    canvas.translate(groundX, groundY);
    canvas.scale(scale);
    canvas.translate(-groundX, -groundY);

    // 3. AMBIENT FLOOR SHADOW (Directly under sneakers, breathing smoothly)
    final shadowScale = 1.0 + math.sin(idleBreath * 2 * math.pi) * 0.04;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(groundX + parallaxX * 0.3, groundY + 4),
        width: 140 * shadowScale,
        height: 28 * shadowScale,
      ),
      shadowPaint,
    );

    // 4. ANATOMICAL ANCHORS (Relative to groundY)
    // Feet / Shoes: groundY - 14 to groundY
    // Ankle cuffs: groundY - 20
    // Knees: groundY - 80
    // Pelvis / Waist: groundY - 140
    // Torso Center: groundY - 195 + breathOffset
    // Shoulder Line: groundY - 240 + breathOffset
    // Neck Base: groundY - 245 + breathOffset
    // Head Center: groundY - 290 + (breathOffset * 0.6) + parallaxY

    final headCenter = Offset(
      groundX + parallaxX,
      groundY - 288 + (breathOffset * 0.6) + parallaxY,
    );

    final shoulderCenter = Offset(
      groundX + parallaxX * 0.7,
      groundY - 238 + breathOffset + parallaxY * 0.6,
    );

    final torsoCenter = Offset(
      groundX + parallaxX * 0.6,
      groundY - 195 + breathOffset + parallaxY * 0.5,
    );

    final waistCenter = Offset(
      groundX + parallaxX * 0.4,
      groundY - 142,
    );

    // 5. BACK LAYER: SPORTS BACKPACK
    if (hasBackpack) {
      _drawBackpackBackLayer(canvas, torsoCenter, parallaxX);
    }

    // 6. BACK LAYER: CRICKET BAT (If Batsman or All-Rounder)
    if (pose == CharacterPose.batsman || pose == CharacterPose.allRounder) {
      _drawCricketBatBack(canvas, shoulderCenter, parallaxX);
    }

    // 7. SNEAKERS & FEET (100% visible on floor)
    _drawSneakers(canvas, groundX, groundY, parallaxX);

    // 8. ATHLETIC TRACK PANTS (Thighs, knees, calves, ankles with Nike swoosh)
    _drawTrackPants(canvas, groundX, groundY, waistCenter, parallaxX);

    // 9. ATHLETIC TORSO & BROAD SHOULDERS (Deltoid caps, sleeve hems)
    _drawBroadShouldersAndTorso(
        canvas, shoulderCenter, torsoCenter, waistCenter, parallaxX, breathOffset);

    // 10. BACKPACK STRAPS OVER CHEST
    if (hasBackpack) {
      _drawBackpackStraps(canvas, shoulderCenter, torsoCenter, parallaxX);
    }

    // 11. HEAD, FACE, SUNGLASSES & OVER-EAR HEADPHONES
    _drawHeadAndFace(canvas, headCenter, parallaxX, parallaxY);

    // 12. ARMS & POSES (Defined biceps, forearms, hands with fingers)
    _drawArmsAndHands(
        canvas, shoulderCenter, torsoCenter, headCenter, parallaxX, breathOffset);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCENE DRAWING: 3D Room from the User's Screenshot
  // ─────────────────────────────────────────────────────────────────────────
  void _drawRoomScene(Canvas canvas, Size size) {
    // Wall Background
    final wallPaint = Paint()..color = const Color(0xFFF3ECE4);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.68), wallPaint);

    // Subtle vertical wooden panel lines on wall
    final panelLinePaint = Paint()
      ..color = const Color(0xFFE5D9CC)
      ..strokeWidth = 1.2;
    for (double x = 18; x < size.width; x += 44) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height * 0.68), panelLinePaint);
    }

    // Baseboard Moulding
    final baseboardPaint = Paint()..color = const Color(0xFFEFE8DE);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.66, size.width, size.height * 0.02),
      baseboardPaint,
    );

    // Room Floor (Light clean neutral tone)
    final floorPaint = Paint()..color = const Color(0xFFDBD1C5);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
      floorPaint,
    );

    // Window on the Right (with trees and sunlight outside)
    final windowRect = Rect.fromLTWH(
      size.width * 0.68,
      size.height * 0.07,
      size.width * 0.38,
      size.height * 0.28,
    );

    // Window frame outer
    canvas.drawRRect(
      RRect.fromRectAndRadius(windowRect, const Radius.circular(4)),
      Paint()..color = Colors.white,
    );

    // Glass interior
    final glassRect = windowRect.deflate(7);
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE), Color(0xFFA5D6A7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(glassRect);
    canvas.drawRect(glassRect, skyPaint);

    // Green Foliage outside window
    final foliagePaint = Paint()..color = const Color(0xFF81C784);
    canvas.drawCircle(
        Offset(glassRect.left + 22, glassRect.bottom - 8), 24, foliagePaint);
    canvas.drawCircle(
        Offset(glassRect.right - 10, glassRect.bottom - 16), 28, foliagePaint);

    // Window Cross Mullions
    final mullionPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(glassRect.center.dx, glassRect.top),
      Offset(glassRect.center.dx, glassRect.bottom),
      mullionPaint,
    );
    canvas.drawLine(
      Offset(glassRect.left, glassRect.center.dy),
      Offset(glassRect.right, glassRect.center.dy),
      mullionPaint,
    );

    // Floating Shelf on the Left
    final shelfRect = Rect.fromLTWH(8, size.height * 0.14, 86, 7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shelfRect, const Radius.circular(2)),
      Paint()..color = Colors.white,
    );

    // Potted plant on shelf
    final potPaint = Paint()..color = const Color(0xFFD7CCC8);
    final potPath = Path()
      ..moveTo(22, shelfRect.top)
      ..lineTo(25, shelfRect.top - 15)
      ..lineTo(40, shelfRect.top - 15)
      ..lineTo(43, shelfRect.top)
      ..close();
    canvas.drawPath(potPath, potPaint);

    // Succulent Leaves
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(32, shelfRect.top - 19), 8, leafPaint);
    canvas.drawCircle(Offset(26, shelfRect.top - 17), 6, leafPaint);
    canvas.drawCircle(Offset(38, shelfRect.top - 18), 6, leafPaint);

    // Small Photo Frame on shelf
    final frameRect = Rect.fromLTWH(52, shelfRect.top - 24, 20, 24);
    canvas.drawRect(frameRect, Paint()..color = Colors.white);
    canvas.drawRect(
        frameRect.deflate(3), Paint()..color = const Color(0xFFE0E0E0));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FULL BODY RIG: SNEAKERS & FEET (Detailed 3D Shoes)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawSneakers(
      Canvas canvas, double groundX, double groundY, double parallaxX) {
    final shoeY = groundY - 6;
    final leftShoeX = groundX - 34 + parallaxX * 0.4;
    final rightShoeX = groundX + 34 + parallaxX * 0.4;

    for (double x in [leftShoeX, rightShoeX]) {
      final isLeft = x == leftShoeX;
      final shoeRect =
          Rect.fromCenter(center: Offset(x, shoeY), width: 38, height: 20);

      // Rubber Midsole (Thick white street sole)
      final solePaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(shoeRect.left - 2, shoeRect.bottom - 7,
              shoeRect.width + 4, 7),
          const Radius.circular(3),
        ),
        solePaint,
      );

      // Black Outsole Tread Line
      final treadPaint = Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(shoeRect.left - 2, shoeRect.bottom),
        Offset(shoeRect.right + 2, shoeRect.bottom),
        treadPaint,
      );

      // Sneaker Upper (Dunk Panda Black, Clean White, or Neon Cricket)
      final upperColor = shoesColorIndex == 0
          ? const Color(0xFF2B2B2B) // Dunk Panda Dark Grey/Black
          : (shoesColorIndex == 1
              ? const Color(0xFFF0F0F0) // Clean White
              : const Color(0xFF00E676)); // Neon Cricket

      final upperPaint = Paint()..color = upperColor;
      final upperPath = Path()
        ..moveTo(shoeRect.left, shoeRect.bottom - 5)
        ..lineTo(shoeRect.left + 5, shoeRect.top)
        ..quadraticBezierTo(shoeRect.center.dx, shoeRect.top - 4,
            shoeRect.right - 2, shoeRect.top + 3)
        ..lineTo(shoeRect.right + 2, shoeRect.bottom - 5)
        ..close();
      canvas.drawPath(upperPath, upperPaint);

      // White Leather Toe Box Overlay
      final toePaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(isLeft ? shoeRect.left + 9 : shoeRect.right - 9,
            shoeRect.bottom - 7),
        8,
        toePaint,
      );

      // White Laces
      final lacePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.6;
      canvas.drawLine(
        Offset(shoeRect.center.dx - 4, shoeRect.top + 4),
        Offset(shoeRect.center.dx + 4, shoeRect.top + 4),
        lacePaint,
      );
      canvas.drawLine(
        Offset(shoeRect.center.dx - 3, shoeRect.top + 8),
        Offset(shoeRect.center.dx + 3, shoeRect.top + 8),
        lacePaint,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FULL BODY RIG: ATHLETIC TRACK PANTS (Thighs, Knees, Calves & Ankles)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawTrackPants(Canvas canvas, double groundX, double groundY,
      Offset waistCenter, double parallaxX) {
    final pantsTopY = waistCenter.dy + 8;
    final pantsBottomY = groundY - 12;

    final pantsPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          pantsColor,
          Color.lerp(pantsColor, Colors.black, 0.35)!,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(groundX - 55, pantsTopY, 110, 160));

    // Left Leg (Athletic taper with natural flare at hem)
    final leftLeg = Path()
      ..moveTo(groundX - 32 + parallaxX * 0.4, pantsTopY)
      ..lineTo(groundX - 44 + parallaxX * 0.3, pantsBottomY)
      ..lineTo(groundX - 18 + parallaxX * 0.3, pantsBottomY)
      ..lineTo(groundX - 6 + parallaxX * 0.4, pantsTopY + 34)
      ..close();
    canvas.drawPath(leftLeg, pantsPaint);

    // Right Leg
    final rightLeg = Path()
      ..moveTo(groundX + 32 + parallaxX * 0.4, pantsTopY)
      ..lineTo(groundX + 44 + parallaxX * 0.3, pantsBottomY)
      ..lineTo(groundX + 18 + parallaxX * 0.3, pantsBottomY)
      ..lineTo(groundX + 6 + parallaxX * 0.4, pantsTopY + 34)
      ..close();
    canvas.drawPath(rightLeg, pantsPaint);

    // Crotch / Pelvis Waistband
    final waistRect = Rect.fromLTWH(
        groundX - 36 + parallaxX * 0.4, pantsTopY - 4, 72, 36);
    canvas.drawRRect(
        RRect.fromRectAndRadius(waistRect, const Radius.circular(8)),
        pantsPaint);

    // White Swoosh Athletic Mark on Right Thigh (Like Nike mark in user screenshot)
    final swooshPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final swooshPath = Path()
      ..moveTo(groundX + 24 + parallaxX * 0.3, pantsTopY + 32)
      ..quadraticBezierTo(
        groundX + 30 + parallaxX * 0.3,
        pantsTopY + 36,
        groundX + 36 + parallaxX * 0.3,
        pantsTopY + 31,
      );
    canvas.drawPath(swooshPath, swooshPaint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FULL BODY RIG: BROAD ATHLETIC SHOULDERS & JERSEY TORSO
  // ─────────────────────────────────────────────────────────────────────────
  void _drawBroadShouldersAndTorso(
      Canvas canvas,
      Offset shoulderCenter,
      Offset torsoCenter,
      Offset waistCenter,
      double parallaxX,
      double breathOffset) {
    final shoulderWidth = 126.0 + breathOffset * 0.8;
    const waistWidth = 74.0;

    // 1. BROAD SHOULDERS & DELTOIDS PATH
    // Spans broadly from left deltoid to right deltoid
    final torsoPath = Path()
      // Base of neck / collar
      ..moveTo(shoulderCenter.dx - 22, shoulderCenter.dy - 12)
      // Left shoulder slope
      ..lineTo(shoulderCenter.dx - (shoulderWidth / 2), shoulderCenter.dy)
      // Left deltoid curve
      ..quadraticBezierTo(
        shoulderCenter.dx - (shoulderWidth / 2) - 8,
        shoulderCenter.dy + 24,
        torsoCenter.dx - (waistWidth / 2) - 6,
        torsoCenter.dy + 20,
      )
      // Left waist down to waistband
      ..lineTo(waistCenter.dx - (waistWidth / 2), waistCenter.dy + 8)
      // Waistband bottom
      ..lineTo(waistCenter.dx + (waistWidth / 2), waistCenter.dy + 8)
      // Right waist up to deltoid
      ..lineTo(torsoCenter.dx + (waistWidth / 2) + 6, torsoCenter.dy + 20)
      // Right deltoid curve
      ..quadraticBezierTo(
        shoulderCenter.dx + (shoulderWidth / 2) + 8,
        shoulderCenter.dy + 24,
        shoulderCenter.dx + (shoulderWidth / 2),
        shoulderCenter.dy,
      )
      // Right shoulder slope to neck
      ..lineTo(shoulderCenter.dx + 22, shoulderCenter.dy - 12)
      ..close();

    final jerseyShader = LinearGradient(
      colors: outfit.shirtColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(
        shoulderCenter.dx - 70, shoulderCenter.dy - 15, 140, 120));

    canvas.drawPath(torsoPath, Paint()..shader = jerseyShader);

    // 2. SHORT SLEEVE CUFF HEMS (Separates upper arms from torso)
    final sleeveHemPaint = Paint()
      ..color = outfit.stripeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    // Left sleeve hem
    canvas.drawLine(
      Offset(shoulderCenter.dx - (shoulderWidth / 2) + 2,
          shoulderCenter.dy + 32),
      Offset(shoulderCenter.dx - (shoulderWidth / 2) + 22,
          shoulderCenter.dy + 26),
      sleeveHemPaint,
    );

    // Right sleeve hem
    canvas.drawLine(
      Offset(shoulderCenter.dx + (shoulderWidth / 2) - 2,
          shoulderCenter.dy + 32),
      Offset(shoulderCenter.dx + (shoulderWidth / 2) - 22,
          shoulderCenter.dy + 26),
      sleeveHemPaint,
    );

    // 3. RIBBED COLLAR (V-neck or crew neck)
    final collarPaint = Paint()
      ..color = outfit.collarColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(shoulderCenter.dx, shoulderCenter.dy - 10),
          width: 32,
          height: 18),
      0,
      math.pi,
      false,
      collarPaint,
    );

    // 4. BRAND TEXT / CREST ("Calvin Klein" or "TURF PRO")
    final brandPainter = TextPainter(
      text: TextSpan(
        text: outfit.brandText,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.7),
          fontSize: 9.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    brandPainter.paint(
      canvas,
      Offset(shoulderCenter.dx - (brandPainter.width / 2),
          shoulderCenter.dy + 12),
    );

    // 5. SQUAD NUMBER on chest
    final numPainter = TextPainter(
      text: TextSpan(
        text: "#$squadNumber",
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.22),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numPainter.paint(
      canvas,
      Offset(shoulderCenter.dx + 16, shoulderCenter.dy + 24),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCESSORIES: SPORTS BACKPACK
  // ─────────────────────────────────────────────────────────────────────────
  void _drawBackpackBackLayer(
      Canvas canvas, Offset torsoCenter, double parallaxX) {
    final bagPaint = Paint()..color = const Color(0xFFFDD835); // Golden yellow
    final bagShadow = Paint()..color = const Color(0xFFFBC02D);

    // Left backpack body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            torsoCenter.dx - 62 + parallaxX * 0.4, torsoCenter.dy - 35, 18, 65),
        const Radius.circular(8),
      ),
      bagShadow,
    );

    // Right backpack body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            torsoCenter.dx + 44 + parallaxX * 0.4, torsoCenter.dy - 35, 18, 65),
        const Radius.circular(8),
      ),
      bagPaint,
    );
  }

  void _drawBackpackStraps(Canvas canvas, Offset shoulderCenter,
      Offset torsoCenter, double parallaxX) {
    final strapPaint = Paint()
      ..color = const Color(0xFFFFF59D) // Light yellow strap
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Left strap over shoulder
    canvas.drawLine(
      Offset(shoulderCenter.dx - 32, shoulderCenter.dy - 8),
      Offset(torsoCenter.dx - 26, torsoCenter.dy + 35),
      strapPaint,
    );

    // Right strap over shoulder
    canvas.drawLine(
      Offset(shoulderCenter.dx + 32, shoulderCenter.dy - 8),
      Offset(torsoCenter.dx + 26, torsoCenter.dy + 35),
      strapPaint,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CRICKET EQUIPMENT: BAT (Back layer)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawCricketBatBack(
      Canvas canvas, Offset shoulderCenter, double parallaxX) {
    canvas.save();
    final batOrigin =
        Offset(shoulderCenter.dx + 46 + parallaxX * 0.6, shoulderCenter.dy - 10);
    canvas.translate(batOrigin.dx, batOrigin.dy);
    canvas.rotate(0.35 + rotateY * 0.2);

    // Bat Blade
    final woodPaint = Paint()..color = const Color(0xFFDEB887);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -75, 20, 90),
        const Radius.circular(4),
      ),
      woodPaint,
    );

    // Bat Rubber Grip
    final gripPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, -75), const Offset(0, -105), gripPaint);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEAD, FACE, SUNGLASSES & OVER-EAR HEADPHONES
  // ─────────────────────────────────────────────────────────────────────────
  void _drawHeadAndFace(Canvas canvas, Offset headCenter, double parallaxX,
      double parallaxY) {
    // 1. Neck
    final neckPaint = Paint()..color = skinTone.shadowColor;
    final neckRect = Rect.fromCenter(
      center: Offset(headCenter.dx, headCenter.dy + 40),
      width: 26,
      height: 24,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(neckRect, const Radius.circular(6)), neckPaint);

    // 2. Ears
    final earPaint = Paint()..color = skinTone.baseColor;
    for (int side in [-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx + (side * 36), headCenter.dy + 6),
          width: 14,
          height: 22,
        ),
        earPaint,
      );
    }

    // 3. Round Snapchat/Bitmoji 3D Head Base
    const headRadius = 38.0;
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        colors: [
          skinTone.highlightColor,
          skinTone.baseColor,
          skinTone.shadowColor,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // 4. Rosy Blush on Cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
        Offset(headCenter.dx - 22, headCenter.dy + 12), 9, blushPaint);
    canvas.drawCircle(
        Offset(headCenter.dx + 22, headCenter.dy + 12), 9, blushPaint);

    // 5. Cute Button Nose
    final noseCenter = Offset(headCenter.dx, headCenter.dy + 10);
    final nosePaint = Paint()
      ..color = skinTone.shadowColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;
    final nosePath = Path()
      ..moveTo(noseCenter.dx - 3, noseCenter.dy)
      ..quadraticBezierTo(
          noseCenter.dx, noseCenter.dy + 3, noseCenter.dx + 3, noseCenter.dy);
    canvas.drawPath(nosePath, nosePaint);

    // 6. Friendly Snapchat Smile (with white teeth)
    final mouthCenter = Offset(headCenter.dx, headCenter.dy + 22);
    final mouthOutline = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.fill;
    final mouthPath = Path()
      ..moveTo(mouthCenter.dx - 11, mouthCenter.dy)
      ..quadraticBezierTo(
          mouthCenter.dx, mouthCenter.dy + 12, mouthCenter.dx + 11, mouthCenter.dy)
      ..close();
    canvas.drawPath(mouthPath, mouthOutline);

    // Teeth
    final teethPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mouthCenter.dx - 8, mouthCenter.dy + 1, 16, 4.2),
        const Radius.circular(2),
      ),
      teethPaint,
    );

    // 7. BEARD / FACIAL HAIR (Snapchat full beard as in screenshot)
    if (hasBeard && gender == AvatarGender.male) {
      final beardPaint = Paint()
        ..color = hairColor
        ..style = PaintingStyle.fill;

      final beardPath = Path()
        ..moveTo(headCenter.dx - 34, headCenter.dy + 12)
        ..quadraticBezierTo(headCenter.dx - 32, headCenter.dy + 42,
            headCenter.dx, headCenter.dy + 48)
        ..quadraticBezierTo(headCenter.dx + 32, headCenter.dy + 42,
            headCenter.dx + 34, headCenter.dy + 12)
        ..lineTo(headCenter.dx + 26, headCenter.dy + 12)
        ..quadraticBezierTo(headCenter.dx, headCenter.dy + 36,
            headCenter.dx - 26, headCenter.dy + 12)
        ..close();
      canvas.drawPath(beardPath, beardPaint);

      // Mustache
      final stachePath = Path()
        ..moveTo(headCenter.dx - 15, headCenter.dy + 16)
        ..quadraticBezierTo(headCenter.dx, headCenter.dy + 13,
            headCenter.dx + 15, headCenter.dy + 16)
        ..quadraticBezierTo(headCenter.dx, headCenter.dy + 20,
            headCenter.dx - 15, headCenter.dy + 16);
      canvas.drawPath(stachePath, beardPaint);
    }

    // 8. EYES OR SUNGLASSES
    final eyeY = headCenter.dy - 3;
    const eyeSpacing = 16.0;

    if (hasSunglasses) {
      // Modern Dark Sunglasses (Wayfarer shades as in user screenshot)
      final shadesPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF263238), Color(0xFF102027)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(headCenter.dx - 34, eyeY - 9, 68, 20));

      final framePaint = Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;

      for (int side in [-1, 1]) {
        final lensRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(headCenter.dx + (side * eyeSpacing), eyeY),
            width: 24,
            height: 16,
          ),
          const Radius.circular(5),
        );
        canvas.drawRRect(lensRect, shadesPaint);
        canvas.drawRRect(lensRect, framePaint);

        // Gloss Reflection Streak
        final glossPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 1.6;
        canvas.drawLine(
          Offset(headCenter.dx + (side * eyeSpacing) - 5, eyeY - 4),
          Offset(headCenter.dx + (side * eyeSpacing) + 2, eyeY + 4),
          glossPaint,
        );
      }

      // Sunglasses Bridge
      canvas.drawLine(
        Offset(headCenter.dx - (eyeSpacing - 12), eyeY),
        Offset(headCenter.dx + (eyeSpacing - 12), eyeY),
        framePaint,
      );
    } else {
      // Expressive Snapchat Big Eyes
      for (int side in [-1, 1]) {
        final eyeCenter = Offset(headCenter.dx + (side * eyeSpacing), eyeY);

        if (isBlinking) {
          final blinkPaint = Paint()
            ..color = const Color(0xFF212121)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(eyeCenter.dx - 8, eyeCenter.dy),
            Offset(eyeCenter.dx + 8, eyeCenter.dy),
            blinkPaint,
          );
        } else {
          canvas.drawOval(
            Rect.fromCenter(center: eyeCenter, width: 16, height: 14),
            Paint()..color = Colors.white,
          );

          final pupilOffset = Offset(
            eyeCenter.dx + rotateY * 2.5,
            eyeCenter.dy + rotateX * 1.5,
          );
          canvas.drawCircle(
              pupilOffset, 5.2, Paint()..color = const Color(0xFF4E342E));
          canvas.drawCircle(pupilOffset, 3.2, Paint()..color = Colors.black);

          canvas.drawCircle(
            Offset(pupilOffset.dx - 1.8, pupilOffset.dy - 1.8),
            1.6,
            Paint()..color = Colors.white,
          );
        }
      }
    }

    // 9. 3D SCULPTED HAIR
    final hairPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          hairColor,
          Color.lerp(hairColor, Colors.white, 0.22)!,
          hairColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: headCenter, radius: 46));

    if (gender == AvatarGender.male) {
      // Modern Stylish Quiff Haircut as in screenshot
      final hairPath = Path()
        ..moveTo(headCenter.dx - 38, headCenter.dy - 12)
        ..quadraticBezierTo(
          headCenter.dx - 40,
          headCenter.dy - 48,
          headCenter.dx,
          headCenter.dy - 50,
        )
        ..quadraticBezierTo(
          headCenter.dx + 40,
          headCenter.dy - 48,
          headCenter.dx + 38,
          headCenter.dy - 12,
        )
        ..quadraticBezierTo(
          headCenter.dx + 20,
          headCenter.dy - 30,
          headCenter.dx,
          headCenter.dy - 26,
        )
        ..quadraticBezierTo(
          headCenter.dx - 20,
          headCenter.dy - 30,
          headCenter.dx - 38,
          headCenter.dy - 12,
        )
        ..close();
      canvas.drawPath(hairPath, hairPaint);
    } else {
      // Sleek High Ponytail for female
      final hairPath = Path()
        ..moveTo(headCenter.dx - 38, headCenter.dy - 8)
        ..quadraticBezierTo(
          headCenter.dx,
          headCenter.dy - 48,
          headCenter.dx + 38,
          headCenter.dy - 8,
        )
        ..quadraticBezierTo(
          headCenter.dx,
          headCenter.dy - 26,
          headCenter.dx - 38,
          headCenter.dy - 8,
        )
        ..close();
      canvas.drawPath(hairPath, hairPaint);

      final ponyPaint = Paint()..color = hairColor;
      canvas.drawCircle(
          Offset(headCenter.dx + 36, headCenter.dy - 22), 16, ponyPaint);
    }

    // 10. OVER-EAR HEADPHONES (Apple AirPods Max style as in screenshot!)
    if (hasHeadphones) {
      const phoneColor = Color(0xFF78909C); // Space grey metallic
      final bandPaint = Paint()
        ..color = const Color(0xFF455A64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round;

      // Canopy Mesh Headband over hair
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(headCenter.dx, headCenter.dy - 16),
          width: 82,
          height: 74,
        ),
        math.pi * 1.12,
        math.pi * 0.76,
        false,
        bandPaint,
      );

      // Aluminum Earcups on sides
      final earcupPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            phoneColor,
            Color.lerp(phoneColor, Colors.white, 0.4)!,
            phoneColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
            Rect.fromLTWH(headCenter.dx - 48, headCenter.dy - 12, 96, 40));

      for (int side in [-1, 1]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(headCenter.dx + (side * 40), headCenter.dy + 4),
              width: 16,
              height: 32,
            ),
            const Radius.circular(8),
          ),
          earcupPaint,
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIVING ARMS & HANDS WITH FINGERS (Snapchat Pose & Cricket Stance)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawArmsAndHands(
      Canvas canvas,
      Offset shoulderCenter,
      Offset torsoCenter,
      Offset headCenter,
      double parallaxX,
      double breathOffset) {
    final armSkinPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          skinTone.highlightColor,
          skinTone.baseColor,
          skinTone.shadowColor,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(
          shoulderCenter.dx - 65, shoulderCenter.dy, 130, 100));

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    if (pose == CharacterPose.crossedArms) {
      // ── CASUAL CROSSED ARMS (Exact pose from User's Screenshot) ──
      // 1. Left Upper Arm (Extends down from left shoulder to left elbow)
      final leftElbow =
          Offset(shoulderCenter.dx - 54 + parallaxX * 0.3, torsoCenter.dy + 26);
      final leftUpperArm = Path()
        ..moveTo(shoulderCenter.dx - 58, shoulderCenter.dy + 12)
        ..lineTo(leftElbow.dx - 8, leftElbow.dy)
        ..quadraticBezierTo(leftElbow.dx, leftElbow.dy + 10, leftElbow.dx + 12,
            leftElbow.dy + 4)
        ..lineTo(shoulderCenter.dx - 36, shoulderCenter.dy + 26)
        ..close();
      canvas.drawPath(leftUpperArm, armSkinPaint);

      // 2. Right Upper Arm (Extends down from right shoulder to right elbow)
      final rightElbow =
          Offset(shoulderCenter.dx + 54 + parallaxX * 0.3, torsoCenter.dy + 26);
      final rightUpperArm = Path()
        ..moveTo(shoulderCenter.dx + 58, shoulderCenter.dy + 12)
        ..lineTo(rightElbow.dx + 8, rightElbow.dy)
        ..quadraticBezierTo(rightElbow.dx, rightElbow.dy + 10,
            rightElbow.dx - 12, rightElbow.dy + 4)
        ..lineTo(shoulderCenter.dx + 36, shoulderCenter.dy + 26)
        ..close();
      canvas.drawPath(rightUpperArm, armSkinPaint);

      // 3. Left Forearm (Folds horizontally across abdomen)
      final leftForearmRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(torsoCenter.dx + 2, torsoCenter.dy + 24),
            width: 82,
            height: 22),
        const Radius.circular(11),
      );
      canvas.drawRRect(leftForearmRect, shadowPaint);
      canvas.drawRRect(leftForearmRect, armSkinPaint);

      // 4. Right Forearm (Crossed over left forearm)
      final rightForearmRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(torsoCenter.dx - 2, torsoCenter.dy + 14),
            width: 84,
            height: 22),
        const Radius.circular(11),
      );
      canvas.drawRRect(rightForearmRect, shadowPaint);
      canvas.drawRRect(rightForearmRect, armSkinPaint);

      // 5. DETAILED HANDS & FINGERS:
      // Left Hand resting over Right Bicep (Thumb & curled fingers)
      final leftHandCenter =
          Offset(shoulderCenter.dx + 42, torsoCenter.dy + 12);
      final handPaint = Paint()..color = skinTone.baseColor;
      final fingerPaint = Paint()
        ..color = skinTone.shadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      // Palm
      canvas.drawOval(
        Rect.fromCenter(center: leftHandCenter, width: 18, height: 14),
        handPaint,
      );
      // Fingers resting on bicep
      for (int i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(leftHandCenter.dx - 6 + (i * 3.5), leftHandCenter.dy - 4),
          Offset(leftHandCenter.dx - 6 + (i * 3.5), leftHandCenter.dy + 4),
          fingerPaint,
        );
      }

      // Right Hand resting under/over Left Bicep
      final rightHandCenter =
          Offset(shoulderCenter.dx - 42, torsoCenter.dy + 6);
      canvas.drawOval(
        Rect.fromCenter(center: rightHandCenter, width: 18, height: 14),
        handPaint,
      );
      for (int i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(rightHandCenter.dx - 5 + (i * 3.5), rightHandCenter.dy - 3),
          Offset(rightHandCenter.dx - 5 + (i * 3.5), rightHandCenter.dy + 4),
          fingerPaint,
        );
      }
    } else if (pose == CharacterPose.batsman) {
      // ── BATSMAN READY: Holding cricket bat with padded batting gloves ──
      final glovePaint = Paint()..color = Colors.white;
      final gloveStripe = Paint()
        ..color = outfit.stripeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Left Arm holding lower handle
      final leftGlove =
          Offset(shoulderCenter.dx + 38, shoulderCenter.dy - 15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: leftGlove, width: 22, height: 24),
          const Radius.circular(6),
        ),
        glovePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: leftGlove, width: 22, height: 24),
          const Radius.circular(6),
        ),
        gloveStripe,
      );

      // Right Arm raised holding upper grip
      final rightGlove =
          Offset(shoulderCenter.dx + 44, shoulderCenter.dy - 40);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: rightGlove, width: 22, height: 24),
          const Radius.circular(6),
        ),
        glovePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: rightGlove, width: 22, height: 24),
          const Radius.circular(6),
        ),
        gloveStripe,
      );

      // Left forearm
      canvas.drawLine(
        Offset(shoulderCenter.dx - 45, shoulderCenter.dy + 15),
        Offset(leftGlove.dx - 8, leftGlove.dy + 8),
        Paint()
          ..color = skinTone.baseColor
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round,
      );
    } else if (pose == CharacterPose.bowler) {
      // ── BOWLER RUN-UP: Holding red leather ball with white seam ──
      final ballOrigin =
          Offset(shoulderCenter.dx + 48, torsoCenter.dy + 12);

      // Right arm extending with ball
      canvas.drawLine(
        Offset(shoulderCenter.dx + 48, shoulderCenter.dy + 10),
        ballOrigin,
        Paint()
          ..color = skinTone.baseColor
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round,
      );

      // Hand holding ball
      canvas.drawCircle(ballOrigin, 14, Paint()..color = skinTone.baseColor);

      // Red Leather Cricket Ball
      final ballPaint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFF3D00), Color(0xFFC62828), Color(0xFF4A0000)],
        ).createShader(Rect.fromCircle(center: ballOrigin, radius: 15));
      canvas.drawCircle(ballOrigin, 15, ballPaint);

      // White Stitched Seam
      final seamPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawArc(
        Rect.fromCircle(center: ballOrigin, radius: 15),
        -math.pi / 4,
        math.pi / 2,
        false,
        seamPaint,
      );

      // Terrycloth Athletic Sweatband at Wrist
      final sweatbandPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(ballOrigin.dx, ballOrigin.dy + 16),
              width: 18,
              height: 10),
          const Radius.circular(3),
        ),
        sweatbandPaint,
      );
    } else {
      // ── ALL-ROUNDER (Bat on shoulder + ball in hand) ──
      final ballOrigin =
          Offset(shoulderCenter.dx - 44, torsoCenter.dy + 14);
      canvas.drawCircle(ballOrigin, 13, Paint()..color = skinTone.baseColor);
      final ballPaint = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFF3D00), Color(0xFFC62828), Color(0xFF4A0000)],
        ).createShader(Rect.fromCircle(center: ballOrigin, radius: 13));
      canvas.drawCircle(ballOrigin, 13, ballPaint);

      final rightGlove =
          Offset(shoulderCenter.dx + 42, shoulderCenter.dy - 25);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: rightGlove, width: 20, height: 22),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnapchatFullBodyAvatarPainter oldDelegate) {
    return oldDelegate.rotateY != rotateY ||
        oldDelegate.rotateX != rotateX ||
        oldDelegate.idleBreath != idleBreath ||
        oldDelegate.isBlinking != isBlinking ||
        oldDelegate.gender != gender ||
        oldDelegate.pose != pose ||
        oldDelegate.skinTone != skinTone ||
        oldDelegate.hairColor != hairColor ||
        oldDelegate.outfit != outfit ||
        oldDelegate.pantsColor != pantsColor ||
        oldDelegate.shoesColorIndex != shoesColorIndex ||
        oldDelegate.squadNumber != squadNumber ||
        oldDelegate.hasSunglasses != hasSunglasses ||
        oldDelegate.hasHeadphones != hasHeadphones ||
        oldDelegate.hasBackpack != hasBackpack ||
        oldDelegate.hasBeard != hasBeard ||
        oldDelegate.stageHeight != stageHeight ||
        oldDelegate.screenWidth != screenWidth;
  }
}
