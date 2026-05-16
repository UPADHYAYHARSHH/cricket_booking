import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/constants/widgets/app_button.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/utils/toast_util.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? passwordError;
  String? confirmPasswordError;

  bool _validateFields() {
    setState(() {
      passwordError = null;
      confirmPasswordError = null;
    });

    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    bool isValid = true;

    if (password.length < 6) {
      setState(() => passwordError = "Password must be at least 6 characters");
      isValid = false;
    }

    if (password != confirmPassword) {
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
        if (state is AuthProfileIncomplete) {
          Navigator.pushReplacementNamed(context, AppRoutes.completeProfile);
        }
        if (state is AuthSuccess) {
          Navigator.pushReplacementNamed(context, AppRoutes.nav);
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
                            text: "Secure Your Account",
                            size: 26,
                            weight: FontWeight.w700,
                          ),
                          const AppSizedBox(height: 6),
                          const AppText(
                            text: "Create a password for your new account",
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
                                const AppText(
                                  text: "Password",
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                                const AppSizedBox(height: 8),
                                 TextField(
                                   controller: passwordController,
                                   obscureText: true,
                                   style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                   decoration: InputDecoration(
                                     hintText: "Create a password",
                                     hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                     errorText: passwordError,
                                     border: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(10),
                                     ),
                                   ),
                                 ),
                                 const AppSizedBox(height: 18),
                                 const AppText(
                                   text: "Confirm Password",
                                   size: 12,
                                   weight: FontWeight.w600,
                                   color: Colors.black54,
                                 ),
                                 const AppSizedBox(height: 8),
                                 TextField(
                                   controller: confirmPasswordController,
                                   obscureText: true,
                                   style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                   decoration: InputDecoration(
                                     hintText: "Repeat your password",
                                     hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                     errorText: confirmPasswordError,
                                     border: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(10),
                                     ),
                                   ),
                                 ),
                                const AppSizedBox(height: 30),
                                  AppButton(
                                    title: "Set Password & Continue",
                                    isLoading: isLoading,
                                    onTap: () {
                                      if (_validateFields()) {
                                        context.read<AuthCubit>().updatePassword(
                                              passwordController.text,
                                            );
                                      }
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
