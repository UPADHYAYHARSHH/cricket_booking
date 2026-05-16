import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/widgets/app_button.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  String? emailError;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetEmailSent) {
          ToastUtil.show(context, 
            message: "Reset link sent! Please check your email.", 
            type: ToastType.success
          );
          Navigator.pop(context);
        }
        if (state is AuthError) {
          ToastUtil.show(context, message: state.message, type: ToastType.error);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
              title: const AppText(text: "Forgot Password", size: 18, weight: FontWeight.w600),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppText(
                          text: "Reset Password",
                          size: 26,
                          weight: FontWeight.w700,
                        ),
                        const AppSizedBox(height: 8),
                        AppText(
                          text: "Enter your email and we'll send you a link to reset your password.",
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          align: TextAlign.center,
                        ),
                        const AppSizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black.withValues(alpha: 0.05)
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: "Email Address",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                              ),
                              const AppSizedBox(height: 8),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: "example@email.com",
                                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                  errorText: emailError,
                                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const AppSizedBox(height: 30),
                              AppButton(
                                title: "Send Reset Link",
                                isLoading: isLoading,
                                onTap: () {
                                  final email = emailController.text.trim();
                                  if (email.isEmpty || !email.contains('@')) {
                                    setState(() => emailError = "Please enter a valid email");
                                    return;
                                  }
                                  context.read<AuthCubit>().sendPasswordResetEmail(email);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
