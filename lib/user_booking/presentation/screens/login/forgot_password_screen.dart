import 'package:turfpro/user_booking/constants/text_theme.dart';
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
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final PageController _pageController = PageController();

  bool isPasswordHidden = true;
  String? errorMessage;
  int _currentStep = 0; // 0: Email, 1: OTP, 2: New Password



  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ToastUtil.show(context, message: state.message, type: ToastType.error);
        } 
        /*
        else if (state is AuthPasswordResetEmailSent) {
          ToastUtil.show(context, message: "Verification code sent to email", type: ToastType.success);
          _nextStep();
        } else if (state is AuthPasswordResetOtpVerified) {
          ToastUtil.show(context, message: "OTP Verified", type: ToastType.success);
          _nextStep();
        } else if (state is AuthPasswordUpdated) {
          ToastUtil.show(context, message: "Password updated successfully!", type: ToastType.success);
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
        */
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: const Color(0xffECECEC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            title: const AppText(text: "Forgot Password", size: 18, weight: FontWeight.w600),
            centerTitle: true,
          ),
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // user can't swipe back manually easily without breaking flow
              children: [
                _buildEmailStep(isLoading),
                _buildOtpStep(isLoading),
                _buildNewPasswordStep(isLoading),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailStep(bool isLoading) {
    return _buildContainer(
      title: "Reset Password",
      subtitle: "Enter your registered email address securely. We will send you an OTP to reset your password.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(text: "Email Address", size: 12, weight: FontWeight.w600, color: Colors.black54),
          const AppSizedBox(height: 8),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDecoration(
              hint: "example@email.com",
              icon: Icons.email_outlined,
              error: _currentStep == 0 ? errorMessage : null,
            ),
          ),
          const AppSizedBox(height: 30),
          AppButton(
            title: "Send OTP",
            isLoading: isLoading,
            onTap: () {
              // if (_validateEmail()) {
              //   context.read<AuthCubit>().sendPasswordResetEmail(emailController.text.trim());
              // }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(bool isLoading) {
    return _buildContainer(
      title: "Verify OTP",
      subtitle: "Enter the verification code sent to ${emailController.text}",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(text: "Verification Code", size: 12, weight: FontWeight.w600, color: Colors.black54),
          const AppSizedBox(height: 8),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDecoration(
              hint: "000000",
              icon: Icons.password,
              error: _currentStep == 1 ? errorMessage : null,
            ),
          ),
          const AppSizedBox(height: 30),
          AppButton(
            title: "Verify",
            isLoading: isLoading,
            onTap: () {
              // if (_validateOtp()) {
              //   context.read<AuthCubit>().verifyPasswordResetOtp(emailController.text.trim(), otpController.text.trim());
              // }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep(bool isLoading) {
    return _buildContainer(
      title: "New Password",
      subtitle: "Enter a strong new password that you haven't used before.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(text: "New Password", size: 12, weight: FontWeight.w600, color: Colors.black54),
          const AppSizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: isPasswordHidden,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Colors.black87),
            decoration: _inputDecoration(
              hint: "Minimum 6 characters",
              icon: Icons.lock_outline,
              error: _currentStep == 2 ? errorMessage : null,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() => isPasswordHidden = !isPasswordHidden);
                },
              ),
            ),
          ),
          const AppSizedBox(height: 30),
          AppButton(
            title: "Update Password",
            isLoading: isLoading,
            onTap: () {
              // if (_validatePassword()) {
              //   context.read<AuthCubit>().updatePassword(passwordController.text.trim());
              // }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required String title, required String subtitle, required Widget child}) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppSizedBox(height: 20),
              AppText(text: title, size: 26, weight: FontWeight.w700, textStyle: AppTextTheme.black17),
              const AppSizedBox(height: 8),
              AppText(text: subtitle, size: 14, color: Colors.grey, align: TextAlign.center),
              const AppSizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.05))],
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, String? error}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      errorText: error,
      prefixIcon: Icon(icon, size: 18, color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
