import 'package:bloc_structure/user_booking/constants/text_theme.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_state.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xffECECEC),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      /// Turf Image
                      Container(
                        height: isDesktop ? 220 : 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage("https://images.unsplash.com/photo-1584464491033-06628f3a6b7b"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: "example@email.com",
                                  border: InputBorder.none,
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

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                controller: passwordController,
                                obscureText: isPasswordHidden,
                                decoration: InputDecoration(
                                  hintText: "Enter password",
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isPasswordHidden = !isPasswordHidden;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const AppSizedBox(height: 24),

                            /// Login Button
                            AppButton(
                              title: "Login",
                              onTap: () {
                                final email = emailController.text.trim();
                                final password = passwordController.text.trim();

                                if (email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Enter email and password"),
                                    ),
                                  );
                                  return;
                                }
                                context.read<AuthCubit>().loginWithEmail(
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                    );
                                // Navigator.pushReplacementNamed(context, AppRoutes.otp);

                                /// Later connect with AuthCubit
                                print("Email: $email");
                                print("Password: $password");
                              },
                            ),
                          ],
                        ),
                      ),

                      const AppSizedBox(height: 40),

                      /// Terms
                      const AppText(
                        text: "By continuing, you agree to our Terms of Service and Privacy Policy",
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
        ));
  }
}
