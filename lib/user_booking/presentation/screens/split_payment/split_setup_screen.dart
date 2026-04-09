import 'dart:io';
import 'package:bloc_structure/user_booking/constants/route_constants.dart';
import 'package:bloc_structure/user_booking/domain/models/booking_arguments.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/split_payment/split_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../common/constants/colors.dart';

import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';

import '../../blocs/split_payment/split_state.dart';
import '../../blocs/user_search/user_search_cubit.dart';
import '../../../di/get_it/get_it.dart';
import '../../widgets/user_card.dart';

class SplitSetupScreen extends StatefulWidget {
  const SplitSetupScreen({super.key});

  @override
  State<SplitSetupScreen> createState() => _SplitSetupScreenState();
}

class _SplitSetupScreenState extends State<SplitSetupScreen> {
  final TextEditingController _memberController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final FocusNode _memberFocus = FocusNode();
  final UserSearchCubit _searchCubit = getIt<UserSearchCubit>();
  BookingSuccessArguments? _args;
  bool _showUserSearch = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookingSuccessArguments) {
      _args = args;
      context.read<SplitPaymentCubit>().initForm(args.totalPrice);
    }
  }

  @override
  void initState() {
    super.initState();
    _memberController.addListener(_onMemberNameChanged);
  }

  @override
  void dispose() {
    _memberController.removeListener(_onMemberNameChanged);
    _memberController.dispose();
    _upiController.dispose();
    _memberFocus.dispose();
    super.dispose();
  }

  void _onMemberNameChanged() {
    final text = _memberController.text;
    print("[DEBUG] SplitSetup: Raw Input: '$text'");
    if (text.startsWith('@')) {
      final query = text.substring(1).trim();
      print("[DEBUG] SplitSetup: Triggering Search for query: '$query'");
      if (!_showUserSearch) setState(() => _showUserSearch = true);
      _searchCubit.searchUsers(query);
    } else {
      if (_showUserSearch) setState(() => _showUserSearch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_args == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocConsumer<SplitPaymentCubit, SplitPaymentState>(
      listener: (context, state) {
        if (state is SplitPaymentSuccess) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.splitOverview,
            arguments: _args!.orderId,
          );
        } else if (state is SplitPaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is! SplitPaymentFormState) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: const AppText(
              text: "Split Bill",
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                const AppSizedBox(height: 24),
                _buildSplitModeToggle(state),
                const AppSizedBox(height: 24),
                _buildMemberSection(state),
                const AppSizedBox(height: 32),
                _buildCollectionSection(state),
                const AppSizedBox(height: 40),
                _buildGenerateButton(state),
                const AppSizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCricketBat,
                    color: Colors.white,
                    size: 20),
              ),
              const AppSizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      text: _args!.ground.name,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    AppText(
                      text: DateFormat('EEE, d MMM • hh:mm a')
                          .format(_args!.date),
                      textStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AppText(
                    text: "TOTAL",
                    textStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                  AppText(
                    text: "₹${_args!.totalPrice.toStringAsFixed(0)}",
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSplitModeToggle(SplitPaymentFormState state) {
    return Row(
      children: [
        Expanded(
          child: _toggleItem(
            "Split Equally",
            state.isEqualSplit,
            () => context.read<SplitPaymentCubit>().toggleSplitMode(true),
          ),
        ),
        const AppSizedBox(width: 12),
        Expanded(
          child: _toggleItem(
            "Custom Amounts",
            !state.isEqualSplit,
            () => context.read<SplitPaymentCubit>().toggleSplitMode(false),
          ),
        ),
      ],
    );
  }

  Widget _toggleItem(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryDarkGreen
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.withOpacity(0.2),
          ),
        ),
        alignment: Alignment.center,
        child: AppText(
          text: label,
          textStyle: TextStyle(
            color: isActive
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMemberSection(SplitPaymentFormState state) {
    final bookerShare = state.totalAmount / (state.members.length + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: "Members & Amounts",
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const AppSizedBox(height: 16),
        // Your Share
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.accentOrange,
                radius: 12,
                child: Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const AppSizedBox(width: 12),
              const Expanded(
                child: AppText(
                    text: "Your Share (Booker)",
                    textStyle: TextStyle(fontWeight: FontWeight.w600)),
              ),
              AppText(
                text: "₹${bookerShare.toStringAsFixed(0)}",
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const AppSizedBox(height: 12),
        // Teammates List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.members.length,
          itemBuilder: (context, index) {
            final member = state.members[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserGroup,
                        color: Colors.grey,
                        size: 16),
                    const AppSizedBox(width: 12),
                    Expanded(
                      child: AppText(
                          text: member.name,
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    if (state.isEqualSplit)
                      AppText(
                        text: "₹${member.amount.toStringAsFixed(0)}",
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    else
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(
                            prefixText: "₹",
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          onChanged: (val) {
                            final amount = double.tryParse(val) ?? 0;
                            context
                                .read<SplitPaymentCubit>()
                                .updateMemberAmount(index, amount);
                          },
                        ),
                      ),
                    const AppSizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red, size: 20),
                      onPressed: () =>
                          context.read<SplitPaymentCubit>().removeMember(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Add member field
        const AppSizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _memberController,
                    focusNode: _memberFocus,
                    onChanged: (val) {
                      if (!val.startsWith('@') && _showUserSearch) {
                        setState(() => _showUserSearch = false);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Member Name or type @username",
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const AppSizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    if (_memberController.text.isNotEmpty) {
                      context
                          .read<SplitPaymentCubit>()
                          .addMember(_memberController.text);
                      _memberController.clear();
                    }
                  },
                  icon: const Icon(Icons.add_circle,
                      color: AppColors.primaryDarkGreen, size: 32),
                ),
              ],
            ),
            if (_showUserSearch)
              Container(
                margin: const EdgeInsets.only(top: 8, right: 44),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: BlocBuilder<UserSearchCubit, UserSearchState>(
                  bloc: _searchCubit,
                  builder: (context, searchState) {
                    if (searchState is UserSearchLoading) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ));
                    }
                    if (searchState is UserSearchLoaded) {
                      if (searchState.users.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Icon(Icons.person_off_outlined,
                                  color: Colors.grey.withValues(alpha: 0.5)),
                              const AppSizedBox(width: 12),
                              const Expanded(
                                child: AppText(
                                    text: "User not found. Try another username.",
                                    textStyle: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: searchState.users.length,
                        itemBuilder: (context, index) {
                          final user = searchState.users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundImage: user['photo_url'] != null
                                  ? NetworkImage(user['photo_url'])
                                  : null,
                              child: user['photo_url'] == null
                                  ? const Icon(Icons.person, size: 15)
                                  : null,
                            ),
                            title: AppText(
                                text: user['name'] ?? '',
                                textStyle: const TextStyle(fontSize: 14)),
                            subtitle: AppText(
                                text: "@${user['username']}",
                                textStyle: const TextStyle(fontSize: 12)),
                            onTap: () {
                              context.read<SplitPaymentCubit>().addLinkedMember(
                                  user['name'] ?? user['username'],
                                  user['id']);
                              _memberController.clear();
                              setState(() => _showUserSearch = false);
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCollectionSection(SplitPaymentFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: "Collect Via",
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const AppSizedBox(height: 16),
        // UPI ID
        TextField(
          controller: _upiController,
          onChanged: (val) =>
              context.read<SplitPaymentCubit>().updateUpiId(val),
          decoration: InputDecoration(
            labelText: "Merchant UPI ID (Optional)",
            hintText: "e.g. yourname@upi",
            prefixIcon: const Icon(Icons.alternate_email),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        const AppSizedBox(height: 16),
        const AppText(
            text: "OR",
            align: TextAlign.center,
            textStyle:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const AppSizedBox(height: 16),
        // QR Code
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              context.read<SplitPaymentCubit>().updateQrImage(File(image.path));
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryDarkGreen.withOpacity(0.2),
                  style: BorderStyle.solid),
            ),
            child: state.qrImage != null
                ? Row(
                    children: [
                      const Icon(Icons.qr_code,
                          color: AppColors.primaryDarkGreen),
                      const AppSizedBox(width: 12),
                      const Expanded(child: AppText(text: "QR Code Selected")),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => context
                            .read<SplitPaymentCubit>()
                            .updateQrImage(null),
                      )
                    ],
                  )
                : const Column(
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          color: AppColors.primaryDarkGreen, size: 32),
                      AppSizedBox(height: 8),
                      AppText(
                          text: "Upload Receipt/UPI QR",
                          textStyle: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(SplitPaymentFormState state) {
    bool canSubmit = state.members.isNotEmpty &&
        (state.upiId.isNotEmpty || state.qrImage != null);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit && !state.isSubmitting
            ? () =>
                context.read<SplitPaymentCubit>().submitSplit(_args!.orderId)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkGreen,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: state.isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const AppText(
                text: "Generate Split Request",
                textStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
      ),
    );
  }
}
