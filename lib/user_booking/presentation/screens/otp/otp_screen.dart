import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:bloc_structure/utils/toast_util.dart';
import '../../../constants/route_constants.dart';
import '../../../constants/widgets/app_button.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Widget _otpBox(int index) {
    return AppSizedBox(
      width: 60,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: "",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onChanged: (value) => _onOtpChanged(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = ModalRoute.of(context)?.settings.arguments as String? ?? "";

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.nav,
            (route) => false,
          );
        }

        if (state is AuthProfileIncomplete) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.signUp,
            (route) => false,
          );
        }

        if (state is AuthError) {
          ToastUtil.show(context, message: state.message, type: ToastType.error);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xffECECEC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),

                const AppSizedBox(height: 20),

                /// Title
                const AppText(
                  text: "Verify Phone",
                  size: 26,
                  weight: FontWeight.w700,
                ),

                const AppSizedBox(height: 6),

                AppText(
                  text: "Enter the 4-digit code sent to $phone",
                  size: 14,
                  color: Colors.grey,
                  align: TextAlign.left,
                ),

                const AppSizedBox(height: 40),

                /// OTP Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _otpBox(0),
                    _otpBox(1),
                    _otpBox(2),
                    _otpBox(3),
                  ],
                ),

                const AppSizedBox(height: 40),

                /// Verify Button
                AppButton(
                  title: "Verify & Continue",
                  onTap: () {
                    final otpCode = _controllers.map((c) => c.text).join();
                    if (otpCode.length < 4) {
                      ToastUtil.show(
                        context,
                        message: "Please enter the full 4-digit code",
                        type: ToastType.warning,
                      );
                      return;
                    }

                    context.read<AuthCubit>().verifyPhoneOtp(phone, otpCode);
                  },
                ),

                const AppSizedBox(height: 30),

                /// Resend Text
                Center(
                  child: Column(
                    children: [
                      const AppText(
                        text: "Didn't receive the code?",
                        size: 13,
                        color: Colors.grey,
                      ),
                      const AppSizedBox(height: 8),
                      GestureDetector(
                        onTap: () {},
                        child: const AppText(
                          text: "Resend OTP",
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const AppSizedBox(height: 6),
                      const AppText(
                        text: "(00:30)",
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
