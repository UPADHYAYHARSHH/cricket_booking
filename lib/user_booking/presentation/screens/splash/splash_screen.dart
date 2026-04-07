import 'package:bloc_structure/user_booking/constants/route_constants.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/di/get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../common/constants/colors.dart';
import '../../blocs/splash/splash_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late SplashCubit splashCubit;

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _progressValue;

  String _statusText = 'SYNCING TURF GROUNDS';
  int _progressPercent = 0;

  @override
  void initState() {
    super.initState();

    splashCubit = getIt<SplashCubit>();

    Future.delayed(const Duration(milliseconds: 2500), () {
      splashCubit.checkAuth(); // ✅ THIS LINE FIXES EVERYTHING
    });

    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progressValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressController.addListener(() {
      setState(() {
        _progressPercent = (_progressController.value * 100).round();

        if (_progressPercent < 30) {
          _statusText = 'SYNCING TURF GROUNDS';
        } else if (_progressPercent < 65) {
          _statusText = 'LOADING LOCATIONS';
        } else if (_progressPercent < 90) {
          _statusText = 'FETCHING SLOTS';
        } else {
          _statusText = 'ALMOST READY';
        }
      });
    });
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _progressController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
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
        },
        child: Scaffold(
          backgroundColor: AppColors.primaryDarkGreen,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isTablet = constraints.maxWidth > 600;

              final logoSize = isDesktop
                  ? 120
                  : isTablet
                      ? 100
                      : 88;

              final titleSize = isDesktop
                  ? 42
                  : isTablet
                      ? 36
                      : 30;

              final padding = isDesktop ? constraints.maxWidth * .25 : 32.0;

              return SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// LOGO
                        FadeTransition(
                          opacity: _logoOpacity,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: _LogoCard(size: logoSize.toDouble()),
                          ),
                        ),

                        const AppSizedBox(height: 30),

                        /// TEXT
                        FadeTransition(
                          opacity: _textOpacity,
                          child: SlideTransition(
                            position: _textSlide,
                            child: _BrandText(titleSize: titleSize.toDouble()),
                          ),
                        ),

                        const AppSizedBox(height: 60),


                        const AppSizedBox(height: 20),

                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (_, __) => _ProgressBar(value: _progressValue.value),
                        ),

                        const AppSizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText(
                              text: _statusText,
                              textStyle: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                            AppText(
                              text: '$_progressPercent%',
                              textStyle: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final double size;

  const _LogoCard({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * .25),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedCricketHelmet,
        color: AppColors.success,
        size: size * .45,
      ),
    );
  }
}

class _BrandText extends StatelessWidget {
  final double titleSize;

  const _BrandText({required this.titleSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText(
          text: 'TURFPRO',
          textStyle: TextStyle(
            color: AppColors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const AppSizedBox(height: 6),
        AppText(
          text: 'SLOT BOOKING ENGINE',
          textStyle: TextStyle(
            color: AppColors.white.withValues(alpha: .65),
            fontSize: titleSize * .35,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: constraints.maxWidth * value,
              height: 4,
              color: AppColors.white,
            ),
          ),
        );
      },
    );
  }
}
