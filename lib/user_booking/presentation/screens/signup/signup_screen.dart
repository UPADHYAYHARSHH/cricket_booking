import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/route_constants.dart';
import '../../../constants/widgets/app_button.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';
import '../../../../common/constants/colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _validateFields() {
    setState(() {
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    bool isValid = true;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => emailError = "Enter a valid email");
      isValid = false;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() => passwordError = "Password must be at least 6 characters");
      isValid = false;
    }

    if (confirmPassword != password) {
      setState(() => confirmPasswordError = "Passwords do not match");
      isValid = false;
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * .15 : 20.0;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess || state is AuthProfileIncomplete) {
          Navigator.pushReplacementNamed(
            context,
            state is AuthProfileIncomplete ? AppRoutes.completeProfile : AppRoutes.nav,
          );
        }
        if (state is AuthEmailOtpRequired) {
          Navigator.pushNamed(context, AppRoutes.waitingVerification, arguments: state.email);
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
              body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        const AppSizedBox(height: 30),
                        const AppText(
                          text: "Create Account",
                          size: 26,
                          weight: FontWeight.w700,
                        ),
                        const AppSizedBox(height: 6),
                        const AppText(
                          text: "Join TurfPro to start booking",
                          size: 14,
                          color: Colors.grey,
                        ),
                        const AppSizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black.withValues(alpha: 0.05),
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
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const AppSizedBox(height: 8),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: "Enter your email",
                                  errorText: emailError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const AppSizedBox(height: 18),
                              AppText(
                                text: "Password",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const AppSizedBox(height: 8),
                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: "Create a password",
                                  errorText: passwordError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const AppSizedBox(height: 18),
                              AppText(
                                text: "Confirm Password",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const AppSizedBox(height: 8),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: "Confirm your password",
                                  errorText: confirmPasswordError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const AppSizedBox(height: 30),
                              AppButton(
                                title: "Sign Up",
                                isLoading: isLoading,
                                onTap: () {
                                  if (_validateFields()) {
                                    context.read<AuthCubit>().signUpWithEmail(
                                          email: emailController.text.trim(),
                                          password: passwordController.text,
                                        );
                                  }
                                },
                              ),
                              const AppSizedBox(height: 20),
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: RichText(
                                    text: const TextSpan(
                                      text: "Already have an account? ",
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                      children: [
                                        TextSpan(
                                          text: "Login",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const AppSizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: AppText(
                                        text: "Verification email may be sent to your spam folder.",
                                        size: 11,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange.shade800,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
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
