import 'package:bloc_structure/user_booking/constants/text_theme.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:bloc_structure/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/route_constants.dart';
import '../../../constants/widgets/app_button.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordHidden = true;
  String? emailError;
  String? passwordError;

  bool _validateFields() {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    bool isValid = true;

    // Email Regex
    final emailRegex = RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]+$");
    if (email.isEmpty) {
      setState(() => emailError = "Email is required");
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => emailError = "Invalid email format");
      isValid = false;
    }

    // Password Length
    if (password.isEmpty) {
      setState(() => passwordError = "Password is required");
      isValid = false;
    } else if (password.length < 6) {
      setState(() => passwordError = "Password must be at least 6 characters");
      isValid = false;
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

          /// ERROR
          if (state is AuthError) {
            ToastUtil.show(message: state.message, type: ToastType.error);
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Scaffold(
              backgroundColor: const Color(0xffECECEC),
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

                          const AppText(
                            text: "Login with your email & password",
                            size: 14,
                            color: Colors.grey,
                          ),

                          const AppSizedBox(height: 30),

                          /// Login Card
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black.withOpacity(.05),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Email
                                const AppText(
                                  text: "Email",
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: Colors.black54,
                                ),

                                const AppSizedBox(height: 8),

                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: "example@email.com",
                                    hintStyle: const TextStyle(color: Colors.black38),
                                    errorText: emailError,
                                    prefixIcon: const Icon(Icons.email_outlined,
                                        size: 18, color: Colors.black54),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),

                                const AppSizedBox(height: 18),

                                /// Password
                                const AppText(
                                  text: "Password",
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: Colors.black54,
                                ),

                                const AppSizedBox(height: 8),

                                TextField(
                                  controller: passwordController,
                                  obscureText: isPasswordHidden,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: "Enter password",
                                    hintStyle: const TextStyle(color: Colors.black38),
                                    errorText: passwordError,
                                    prefixIcon: const Icon(Icons.lock_outlined,
                                        size: 18, color: Colors.black54),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordHidden
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          isPasswordHidden = !isPasswordHidden;
                                        });
                                      },
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
                                            password:
                                                passwordController.text.trim(),
                                          );
                                    }
                                  },
                                ),

                                const AppSizedBox(height: 20),

                                /// Go to Signup
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, AppRoutes.signUp);
                                    },
                                    child: RichText(
                                      text: const TextSpan(
                                        text: "Don't have an account? ",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 13),
                                        children: [
                                          TextSpan(
                                            text: "Sign Up",
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
                              ],
                            ),
                          ),

                          const AppSizedBox(height: 40),

                          /// Terms
                          const AppText(
                            text:
                                "By continuing, you agree to our Terms of Service and Privacy Policy",
                            size: 12,
                            color: Colors.grey,
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
