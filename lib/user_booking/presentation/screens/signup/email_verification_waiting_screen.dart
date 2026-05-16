import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/common/constants/colors.dart';

class EmailVerificationWaitingScreen extends StatelessWidget {
  const EmailVerificationWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? "";

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthVerified) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.completeProfile,
          );
        }
      },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      size: 80,
                      color: Colors.green,
                    ),
                    const AppSizedBox(height: 30),
                    const AppText(
                      text: "Verify Your Email",
                      size: 26,
                      weight: FontWeight.w700,
                    ),
                    const AppSizedBox(height: 12),
                    AppText(
                      text: "We've sent a verification link to:",
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    AppText(
                      text: email,
                      size: 16,
                      weight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const AppSizedBox(height: 40),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const AppSizedBox(height: 24),
                    const AppText(
                      text: "Waiting for verification...",
                      size: 14,
                      color: Colors.grey,
                      align: TextAlign.center,
                    ),
                    const AppSizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          AppText(
                            text: "Can't find it? Check your spam folder",
                            size: 12,
                            color: Colors.orange.shade800,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                    const AppSizedBox(height: 60),
                    TextButton(
                      onPressed: () => context.read<AuthCubit>().checkSession(),
                      child: const AppText(
                        text: "I've Verified My Email",
                        color: Colors.green,
                        weight: FontWeight.w700,
                        size: 16,
                      ),
                    ),
                    const AppSizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: AppText(
                        text: "Change Email",
                        color: Colors.grey.shade600,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}
