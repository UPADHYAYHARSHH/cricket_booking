
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/auth/auth_state.dart';
import 'package:bloc_structure/user_booking/data/repositories/user_repository_impl.dart';
import 'package:bloc_structure/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:bloc_structure/user_booking/di/get_it/get_it.dart' as di;

import '../../../constants/route_constants.dart';
import '../../../constants/widgets/app_button.dart';
import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  String? nameError;
  String selectedGender = "Male";
  DateTime? selectedDate;

  bool _validateFields() {
    setState(() {
      nameError = null;
    });

    final name = nameController.text.trim();
    bool isValid = true;

    if (name.isEmpty) {
      setState(() => nameError = "Name is required");
      isValid = false;
    }

    if (selectedDate == null) {
      ToastUtil.show(context, message: "Please select your date of birth", type: ToastType.warning);
      isValid = false;
    }

    return isValid;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * .15 : 20.0;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
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
            backgroundColor: const Color(0xffECECEC),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        const AppSizedBox(height: 30),
                        const AppText(
                          text: "Complete Your Profile",
                          size: 26,
                          weight: FontWeight.w700,
                        ),
                        const AppSizedBox(height: 6),
                        const AppText(
                          text: "Just a few more details to get started",
                          size: 14,
                          color: Colors.grey,
                        ),
                        const AppSizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                text: "Full Name",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              const AppSizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "Enter your name",
                                  errorText: nameError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const AppSizedBox(height: 18),
                              const AppText(
                                text: "Gender",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              const AppSizedBox(height: 8),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text("Male"),
                                    selected: selectedGender == "Male",
                                    onSelected: (val) => setState(() => selectedGender = "Male"),
                                  ),
                                  const AppSizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text("Female"),
                                    selected: selectedGender == "Female",
                                    onSelected: (val) => setState(() => selectedGender = "Female"),
                                  ),
                                ],
                              ),
                              const AppSizedBox(height: 18),
                              const AppText(
                                text: "Date of Birth",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              const AppSizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      AppText(
                                        text: selectedDate == null
                                            ? "Select Date"
                                            : DateFormat('dd/MM/yyyy').format(selectedDate!),
                                        color: selectedDate == null ? Colors.black38 : Colors.black87,
                                      ),
                                      const Icon(Icons.calendar_today, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                              const AppSizedBox(height: 30),
                              AppButton(
                                title: "Save & Continue",
                                isLoading: isLoading,
                                onTap: () {
                                  if (_validateFields()) {
                                    context.read<AuthCubit>().completeProfile(
                                          name: nameController.text.trim(),
                                          gender: selectedGender,
                                          dob: selectedDate!,
                                          userRepository: di.getIt<UserRepository>(),
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
