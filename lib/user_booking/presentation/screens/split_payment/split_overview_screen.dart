import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/constants/colors.dart';

import '../../../constants/widgets/app_sizedBox.dart';
import '../../../constants/widgets/app_text.dart';
import '../../blocs/split_payment/split_cubit.dart';
import '../../blocs/split_payment/split_state.dart';

class SplitOverviewScreen extends StatefulWidget {
  const SplitOverviewScreen({super.key});

  @override
  State<SplitOverviewScreen> createState() => _SplitOverviewScreenState();
}

class _SplitOverviewScreenState extends State<SplitOverviewScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      context.read<SplitPaymentCubit>().loadSplitOverview(args);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplitPaymentCubit, SplitPaymentState>(
      listener: (context, state) {
        if (state is SplitPaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is SplitPaymentLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (state is! SplitPaymentOverviewLoaded) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: AppText(text: "Something went wrong")),
          );
        }

        final split = state.splitRequest;
        final collected = split.members
            .where((m) => m.isReceived)
            .fold(0.0, (sum, item) => sum + item.amount);
        final totalToCollect =
            split.members.fold(0.0, (sum, item) => sum + item.amount);
        final progress = totalToCollect > 0 ? collected / totalToCollect : 0.0;
        final myShare = split.totalAmount - totalToCollect;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close,
                  color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: const AppText(
              text: "Split Overview",
              textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildProgressCard(collected, totalToCollect, progress),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const AppText(
                      text: "Teammates Status",
                      textStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const AppSizedBox(height: 16),
                    ...split.members.map((m) => _buildMemberTile(m, split)),
                    const AppSizedBox(height: 24),
                    _buildSummaryRow("Total Booking Amount",
                        "₹${split.totalAmount.toStringAsFixed(0)}"),
                    _buildSummaryRow(
                        "Your Share (Paid)", "₹${myShare.toStringAsFixed(0)}"),
                    _buildSummaryRow("Teammates Share",
                        "₹${totalToCollect.toStringAsFixed(0)}"),
                  ],
                ),
              ),
              _buildBottomAction(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(double collected, double total, double progress) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    text: "COLLECTED",
                    textStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                  AppText(
                    text: "₹${collected.toStringAsFixed(0)}",
                    textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AppText(
                  text: "${(progress * 100).toInt()}%",
                  textStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const AppSizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const AppSizedBox(height: 12),
          AppText(
            text:
                "₹${(total - collected).toStringAsFixed(0)} more pending from teammates",
            textStyle: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(dynamic member, dynamic split) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: member.isReceived
                ? AppColors.primaryDarkGreen.withValues(alpha: 0.2)
                : Colors.transparent),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: member.isReceived
                ? AppColors.primaryDarkGreen
                : Colors.grey.shade200,
            child: Icon(member.isReceived ? Icons.check : Icons.person,
                color: member.isReceived ? Colors.white : Colors.grey),
          ),
          const AppSizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: member.name,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                AppText(
                  text: "₹${member.amount.toStringAsFixed(0)}",
                  textStyle: const TextStyle(
                      color: AppColors.primaryDarkGreen,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  member.isReceived ? Icons.undo : Icons.check_circle,
                  color: member.isReceived
                      ? Colors.grey
                      : AppColors.primaryDarkGreen,
                ),
                onPressed: () {
                  context
                      .read<SplitPaymentCubit>()
                      .toggleMemberReceived(member.id, !member.isReceived);
                },
              ),
              const AppText(
                  text: "Status",
                  textStyle: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const AppSizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.blue),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.splitShare, arguments: {
                'name': member.name,
                'amount': member.amount,
                'venue': "Venue", // Ideal to pass real venue name
                'date': "Date",
                'time': "Time",
                'upiId': split.upiId ?? "",
                'qrUrl': split.qrCodeUrl,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
              text: label,
              textStyle: const TextStyle(color: Colors.grey, fontSize: 14)),
          AppText(
              text: value,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.nav, (r) => false),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDarkGreen,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const AppText(
            text: "Go to Home",
            textStyle:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
