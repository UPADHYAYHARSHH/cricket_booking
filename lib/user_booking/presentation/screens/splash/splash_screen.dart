import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/splash/slottix_splash.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/common/screens/maintenance_screen.dart';
import '../../blocs/splash/splash_cubit.dart';
import 'app_status_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late SplashCubit _splashCubit;
  SplashState? _pendingState;

  @override
  void initState() {
    super.initState();
    _splashCubit = getIt<SplashCubit>();
  }

  Future<void> _onReady() async {
    _splashCubit.checkStatus();

    // If already resolved to a final state
    if (_isFinalState(_splashCubit.state)) {
      _pendingState = _splashCubit.state;
      return;
    }

    try {
      _pendingState = await _splashCubit.stream
          .firstWhere((s) => _isFinalState(s))
          .timeout(const Duration(milliseconds: 4000));
    } catch (_) {
      _pendingState = _splashCubit.state;
    }
  }

  bool _isFinalState(SplashState s) {
    return s is! SplashInitial;
  }

  void _onDone() {
    if (!mounted) return;
    final state = _pendingState ?? _splashCubit.state;
    _performNavigation(state);
  }

  void _performNavigation(SplashState state) {
    if (state is SplashNavigateToHome) {
      Navigator.pushReplacementNamed(context, AppRoutes.nav);
    } else if (state is SplashNavigateToLogin) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (state is SplashNavigateToCompleteProfile) {
      Navigator.pushReplacementNamed(context, AppRoutes.completeProfile);
    } else if (state is SplashUnderMaintenance) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
        (route) => false,
      );
    } else if (state is SplashUpdateRequired) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ForceUpdateDialog(updateUrl: state.updateUrl),
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _splashCubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          _pendingState = state;
        },
        child: SlottixSplash(
          variant: SplashVariant.user,
          sound: SplashSound.classicCourt,
          onReady: _onReady,
          onDone: _onDone,
        ),
      ),
    );
  }
}
