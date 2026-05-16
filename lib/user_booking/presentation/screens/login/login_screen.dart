import 'package:turfpro/user_booking/constants/text_theme.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? phoneError;
  String? emailError;
  String? passwordError;

  bool isEmailLogin = false;

  bool _validateFields() {
    setState(() {
      phoneError = null;
      emailError = null;
      passwordError = null;
    });

    bool isValid = true;

    if (isEmailLogin) {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (email.isEmpty || !email.contains('@')) {
        setState(() => emailError = "Enter a valid email");
        isValid = false;
      }
      if (password.isEmpty) {
        setState(() => passwordError = "Password is required");
        isValid = false;
      }
    } else {
      final phone = phoneController.text.trim();
      if (phone.isEmpty) {
        setState(() => phoneError = "Phone number is required");
        isValid = false;
      } else if (phone.length != 10) {
        setState(() => phoneError = "Enter a valid 10-digit number");
        isValid = false;
      }
    }

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600;

    final horizontalPadding = isDesktop
        ? screenWidth * .30
        : isTablet
            ? screenWidth * .15
            : 20.0;

    return BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushReplacementNamed(context, AppRoutes.nav);
          }

          if (state is AuthProfileIncomplete) {
            Navigator.pushReplacementNamed(context, AppRoutes.completeProfile);
          }

          if (state is AuthEmailOtpRequired) {
            Navigator.pushNamed(context, AppRoutes.waitingVerification, arguments: state.email);
          }

          /// ERROR
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
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        children: [
                          /// Turf Image
                          Container(
                            height: isDesktop ? 220 : 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: const DecorationImage(
                                image: NetworkImage(
                                    "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b"),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const AppText(
                                  text: "PREMIUM TURFS",
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const AppSizedBox(height: 30),

                          /// Title
                          const AppText(
                            text: "Welcome Back!",
                            size: 26,
                            weight: FontWeight.w700,
                            textStyle: AppTextTheme.black17,
                          ),

                          const AppSizedBox(height: 6),

                          AppText(
                            text: "Login to your account",
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),

                          const AppSizedBox(height: 30),

                          /// Login Card
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Email
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
                                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                    errorText: emailError,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                    ),
                                  ),
                                ),
                                const AppSizedBox(height: 18),
                                /// Password
                                AppText(
                                  text: "Password",
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const AppSizedBox(height: 8),
                                TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  decoration: InputDecoration(
                                    hintText: "Enter your password",
                                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                    errorText: passwordError,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                                    ),
                                  ),
                                ),

                                const AppSizedBox(height: 12),

                                /// Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, AppRoutes.forgotPassword);
                                    },
                                    child: const AppText(
                                      text: "Forgot Password?",
                                      size: 13,
                                      color: Colors.green,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                const AppSizedBox(height: 30),

                                /// Login Button
                                AppButton(
                                  title: "Login",
                                  isLoading: isLoading,
                                  onTap: () {
                                    if (_validateFields()) {
                                      context.read<AuthCubit>().loginWithEmail(
                                            email: emailController.text.trim(),
                                            password: passwordController.text,
                                          );
                                    }
                                  },
                                ),

/*
                                /// Forgot Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, AppRoutes.forgotPassword);
                                    },
                                    child: const AppText(
                                      text: "Forgot Password?",
                                      size: 13,
                                      color: Colors.green,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
*/

                                const AppSizedBox(height: 20),

                                /// Go to Signup
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, AppRoutes.signUp);
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Don't have an account? ",
                                        style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                                        children: [
                                          TextSpan(
                                            text: "Sign Up",
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const AppSizedBox(height: 40),

                          /// Terms
                          AppText(
                            text:
                                "By continuing, you agree to our Terms of Service and Privacy Policy",
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            align: TextAlign.center,
                          ),

                          const AppSizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ));
  }
}
