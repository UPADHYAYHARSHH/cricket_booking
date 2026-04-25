import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_button.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🎨 Lottie Animation
              Center(
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_0yfs9h.json', // Connection lost animation
                  height: 250,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        size: 80,
                        color: AppColors.primaryDarkGreen,
                      ),
                    );
                  },
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const AppSizedBox(height: 40),

              // 📝 Title
              AppText(
                text: "No Internet Connection",
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const AppSizedBox(height: 12),

              // 💬 Description
              AppText(
                text: "Oops! It seems you're offline. Please check your network settings and try again.",
                align: TextAlign.center,
                textStyle: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

              const AppSizedBox(height: 48),

              // 🔘 Retry Button
              AppButton(
                title: "Retry Connection",
                onTap: () {
                  context.read<ConnectivityCubit>().checkConnectivity();
                },
              ).animate().fadeIn(delay: 600.ms).scale(duration: 400.ms),
              
              const AppSizedBox(height: 16),
              
              // 🌐 Status Text
              AppText(
                text: "Waiting for signal...",
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
