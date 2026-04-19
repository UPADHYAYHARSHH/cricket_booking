import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:bloc_structure/utils/toast_util.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';
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
  late final TextEditingController pinController;
  late final FocusNode focusNode;
  final SmartAuth smartAuth = SmartAuth.instance;

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
    focusNode = FocusNode();
    _listenForSms();
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    smartAuth.removeUserConsentApiListener();
    super.dispose();
  }

  void _listenForSms() async {
    final res = await smartAuth.getAppSignature();
    debugPrint("DEBUG: [OtpScreen] App Signature: $res");

    await smartAuth.getSmsWithUserConsentApi().then((res) {
      if (res.hasData && res.requireData.code != null) {
        pinController.text = res.requireData.code!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final phone = ModalRoute.of(context)?.settings.arguments as String? ?? "";

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: Colors.green, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: Colors.green.withOpacity(0.05),
        border: Border.all(color: Colors.green),
      ),
    );

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
          ToastUtil.show(context,
              message: state.message, type: ToastType.error);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: const Color(0xffECECEC),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
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
                        text: "Enter the 6-digit code sent to $phone",
                        size: 14,
                        color: Colors.grey,
                        align: TextAlign.left,
                      ),

                      const AppSizedBox(height: 40),

                      /// Pinput Field
                      Center(
                        child: Pinput(
                          length: 6,
                          controller: pinController,
                          focusNode: focusNode,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: submittedPinTheme,
                          hapticFeedbackType: HapticFeedbackType.lightImpact,
                          onCompleted: (pin) {
                            debugPrint(
                                "DEBUG: [OtpScreen] PIN completed: $pin");
                            context
                                .read<AuthCubit>()
                                .verifyPhoneOtp(phone, pin);
                          },
                          cursor: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 9),
                                width: 22,
                                height: 2,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const AppSizedBox(height: 40),

                      /// Verify Button
                      AppButton(
                        title: "Verify & Continue",
                        isLoading: isLoading,
                        onTap: () {
                          final otpCode = pinController.text;
                          if (otpCode.length < 6) {
                            ToastUtil.show(
                              context,
                              message: "Please enter the full 6-digit code",
                              type: ToastType.warning,
                            );
                            return;
                          }

                          context
                              .read<AuthCubit>()
                              .verifyPhoneOtp(phone, otpCode);
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
                              onTap: () {
                                if (!isLoading) {
                                  context
                                      .read<AuthCubit>()
                                      .signInWithPhone(phone);
                                }
                              },
                              child: AppText(
                                text: "Resend OTP",
                                size: 14,
                                weight: FontWeight.w600,
                                color: isLoading ? Colors.grey : Colors.green,
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
        },
      ),
    );
  }
}
