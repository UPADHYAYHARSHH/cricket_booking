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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  String? phoneError;

  bool _validateFields() {
    setState(() {
      phoneError = null;
    });

    final phone = phoneController.text.trim();

    bool isValid = true;

    if (phone.isEmpty) {
      setState(() => phoneError = "Phone number is required");
      isValid = false;
    } else if (phone.length != 10) {
      setState(() => phoneError = "Enter a valid 10-digit number");
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

          if (state is AuthOtpRequired) {
            Navigator.pushNamed(
              context,
              AppRoutes.otp,
              arguments: "+91${phoneController.text.trim()}",
            );
          }

          if (state is AuthProfileIncomplete) {
            Navigator.pushReplacementNamed(context, AppRoutes.signUp);
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
                            text: "Login with your phone number",
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
                                /// Phone Number
                                const AppText(
                                  text: "Phone Number",
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: Colors.black54,
                                ),

                                const AppSizedBox(height: 8),

                                TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    hintText: "Enter 10 digit number",
                                    hintStyle: const TextStyle(color: Colors.black38),
                                    errorText: phoneError,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      child: Text(
                                        "+91",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
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

                                const AppSizedBox(height: 30),

                                /// Login Button
                                AppButton(
                                  title: "Send OTP",
                                  isLoading: isLoading,
                                  onTap: () {
                                    if (_validateFields()) {
                                      final phone = "+91${phoneController.text.trim()}";
                                      print("DEBUG: [LoginScreen] Send OTP button pressed for: $phone");
                                      context.read<AuthCubit>().signInWithPhone(phone);
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
