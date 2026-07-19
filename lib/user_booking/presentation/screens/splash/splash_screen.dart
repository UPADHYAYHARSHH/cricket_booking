import 'dart:math' as math;
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/splash/splash_cubit.dart';
import 'app_status_screens.dart';
import 'package:turfpro/common/screens/maintenance_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late SplashCubit splashCubit;

  late AnimationController _controller;

  // Pitch line
  late Animation<double> _pitchLineHeight;

  // Stumps
  late Animation<double> _stump1Offset;
  late Animation<double> _stump2Offset;
  late Animation<double> _stump3Offset;

  late Animation<double> _stump1Opacity;
  late Animation<double> _stump2Opacity;
  late Animation<double> _stump3Opacity;

  // Bail
  late Animation<double> _bailOpacity;

  // Ball
  late Animation<double> _ballTop;
  late Animation<double> _ballLeft;
  late Animation<double> _ballRotation;
  late Animation<double> _ballOpacity;

  // Flash
  late Animation<double> _flashOpacity;

  // Brand
  late Animation<double> _brandOpacity;

  // Loader
  late Animation<double> _loaderOpacity;

  @override
  void initState() {
    super.initState();
    splashCubit = getIt<SplashCubit>();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _setupAnimations();

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        splashCubit.checkStatus();
      }
    });
  }

  void _setupAnimations() {
    // 0.1s to 0.6s (Pitch Line) => 100/2800 = 0.0357, 600/2800 = 0.2143
    _pitchLineHeight = Tween<double>(begin: 0, end: 110).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0357, 0.2143, curve: Curves.ease),
      ),
    );

    // Stumps
    // Stump 1: 0.35s to 0.85s => 0.125 to 0.3035
    _stump1Offset = Tween<double>(begin: 70, end: 0).animate(
      CurvedAnimation(
          parent: _controller,
          curve:
              const Interval(0.125, 0.3035, curve: Cubic(0.2, 0.9, 0.3, 1.2))),
    );
    _stump1Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.125, 0.3035, curve: Curves.ease)),
    );

    // Stump 2: 0.45s to 0.95s => 0.1607 to 0.3393
    _stump2Offset = Tween<double>(begin: 70, end: 0).animate(
      CurvedAnimation(
          parent: _controller,
          curve:
              const Interval(0.1607, 0.3393, curve: Cubic(0.2, 0.9, 0.3, 1.2))),
    );
    _stump2Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.1607, 0.3393, curve: Curves.ease)),
    );

    // Stump 3: 0.55s to 1.05s => 0.1964 to 0.375
    _stump3Offset = Tween<double>(begin: 70, end: 0).animate(
      CurvedAnimation(
          parent: _controller,
          curve:
              const Interval(0.1964, 0.375, curve: Cubic(0.2, 0.9, 0.3, 1.2))),
    );
    _stump3Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.1964, 0.375, curve: Curves.ease)),
    );

    // Bail: 0.85s to 1.15s => 0.3035 to 0.4107
    _bailOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3035, 0.4107, curve: Curves.ease)),
    );

    // Ball: 1.05s to 2.15s => 0.375 to 0.7678
    // 0% -> 60% -> 100% inside this interval
    _ballTop = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 120, end: 460)
              .chain(CurveTween(curve: Curves.easeInQuad)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween<double>(begin: 460, end: 270)
              .chain(CurveTween(curve: Curves.easeOutQuad)),
          weight: 40),
    ]).animate(
      CurvedAnimation(
          parent: _controller,
          curve:
              const Interval(0.375, 0.7678, curve: Cubic(0.3, 0.6, 0.2, 1.0))),
    );

    _ballLeft = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: -30, end: 180)
              .chain(CurveTween(curve: Curves.linear)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween<double>(begin: 180, end: 198)
              .chain(CurveTween(curve: Curves.linear)),
          weight: 40),
    ]).animate(
      CurvedAnimation(
          parent: _controller,
          curve:
              const Interval(0.375, 0.7678, curve: Cubic(0.3, 0.6, 0.2, 1.0))),
    );

    _ballRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 360), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 360, end: 540), weight: 40),
    ]).animate(
      CurvedAnimation(
          parent: _controller,
          curve:
              const Interval(0.375, 0.7678, curve: Cubic(0.3, 0.6, 0.2, 1.0))),
    );

    _ballOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 95),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 5),
    ]).animate(
      CurvedAnimation(
          parent: _controller, curve: const Interval(0.375, 0.7678)),
    );

    // Flash: 2.05s to 2.33s => 0.7321 to 0.8321
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 0.85)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween<double>(begin: 0.85, end: 0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 60),
    ]).animate(
      CurvedAnimation(
          parent: _controller, curve: const Interval(0.7321, 0.8321)),
    );

    // Brand: 2.15s to 2.65s => 0.7678 to 0.9464
    _brandOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.7678, 0.9464, curve: Curves.ease)),
    );

    // Loader: 2.4s to 2.8s => 0.8571 to 1.0
    _loaderOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.8571, 1.0, curve: Curves.ease)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => splashCubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashNavigateToHome) {
            Navigator.pushReplacementNamed(context, AppRoutes.nav);
          }

          if (state is SplashNavigateToLogin) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }

          if (state is SplashUnderMaintenance) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
              (route) => false,
            );
          }

          if (state is SplashUpdateRequired) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => ForceUpdateDialog(updateUrl: state.updateUrl),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF173D2B), // --turf
          body: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 390,
                  height: 844,
                  child: Stack(
                    children: [
                      // Stage Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF173D2B), Color(0xFF0F2B1E)],
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -0.6), // 50% 20% -> y=-0.6
                            radius: 0.55,
                            colors: [
                              Color(0x0DFFFFFF),
                              Colors.transparent
                            ], // rgba(255,255,255,0.05)
                          ),
                        ),
                      ),

                      // Pitch Line
                      AnimatedBuilder(
                        animation: _pitchLineHeight,
                        builder: (context, child) {
                          return Positioned(
                            bottom: 210,
                            left: 194, // 390/2 - 2/2 = 194
                            child: Container(
                              width: 2,
                              height: _pitchLineHeight.value,
                              color: const Color(
                                  0x59F7F5EE), // rgba(247,245,238,0.35)
                            ),
                          );
                        },
                      ),

                      // Stumps
                      Positioned(
                        bottom: 210,
                        left: 177, // 390/2 - (18+18)/2 = 195 - 18 = 177
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildStump(_stump1Offset, _stump1Opacity, 64),
                            const SizedBox(width: 9),
                            _buildStump(_stump2Offset, _stump2Opacity, 70),
                            const SizedBox(width: 9),
                            _buildStump(_stump3Offset, _stump3Opacity, 64),
                          ],
                        ),
                      ),

                      // Bail
                      AnimatedBuilder(
                        animation: _bailOpacity,
                        builder: (context, child) {
                          return Positioned(
                            bottom: 274,
                            left: 182, // 390/2 - 26/2 = 182
                            child: Opacity(
                              opacity: _bailOpacity.value,
                              child: Container(
                                width: 26,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEADFC4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Ball
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Positioned(
                            top: _ballTop.value,
                            left: _ballLeft.value,
                            child: Opacity(
                              opacity: _ballOpacity.value,
                              child: Transform.rotate(
                                angle: _ballRotation.value * math.pi / 180,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      center: Alignment(-0.3, -0.4),
                                      colors: [
                                        Color(0xFFFF8358),
                                        Color(0xFFE8622C)
                                      ],
                                      stops: [0.0, 0.7],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(
                                            0x4D000000), // rgba(0,0,0,0.3)
                                        blurRadius: 14,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Flash
                      AnimatedBuilder(
                        animation: _flashOpacity,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: _flashOpacity.value,
                                child: Container(
                                  color: const Color(0xFFF7F5EE), // --chalk
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Brand & Tagline
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Positioned.fill(
                            child: Opacity(
                              opacity: _brandOpacity.value,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 36,
                                        letterSpacing: -0.72, // -0.02em
                                        color: const Color(0xFFF7F5EE),
                                      ),
                                      children: const [
                                        TextSpan(text: 'TURF'),
                                        TextSpan(
                                          text: 'PRO',
                                          style: TextStyle(
                                              color: Color(0xFFE8622C)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'YOUR GROUND, ONE TAP AWAY',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      letterSpacing: 1.82, // 0.14em
                                      color: const Color(
                                          0x8CF7F5EE), // rgba(247,245,238,0.55)
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Loader
                      AnimatedBuilder(
                        animation: _loaderOpacity,
                        builder: (context, child) {
                          return Positioned(
                            bottom: 70,
                            left: 178, // 390/2 - 34/2 = 178
                            child: Opacity(
                              opacity: _loaderOpacity.value,
                              child: const SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFE8622C)),
                                  backgroundColor: Color(
                                      0x40F7F5EE), // rgba(247,245,238,0.25)
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStump(
      Animation<double> offset, Animation<double> opacity, double height) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, offset.value),
          child: Opacity(
            opacity: opacity.value.clamp(0.0, 1.0),
            child: Container(
              width: 6,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEADFC4), Color(0xFFC9B98E)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                  bottomLeft: Radius.circular(1),
                  bottomRight: Radius.circular(1),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
