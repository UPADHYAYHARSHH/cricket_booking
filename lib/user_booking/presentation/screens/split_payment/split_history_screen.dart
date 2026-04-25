import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/domain/models/split_payment_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/split_history/split_history_cubit.dart';
import '../../../di/get_it/get_it.dart';

import '../../../constants/widgets/app_text.dart';
import '../../../constants/widgets/app_sizedBox.dart';

import '../../../constants/route_constants.dart';

class SplitHistoryScreen extends StatelessWidget {
  const SplitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return BlocProvider(
      create: (context) => getIt<SplitHistoryCubit>()..fetchHistory(),
      child: Scaffold(
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
            text: "Split Bill History",
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<SplitHistoryCubit, SplitHistoryState>(
          builder: (context, state) {
            if (state is SplitHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SplitHistoryError) {
              return Center(child: AppText(text: "Error: ${state.message}"));
            }

            if (state is SplitHistoryLoaded) {
              if (state.splits.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: Colors.grey.withOpacity(0.2)),
                      const AppSizedBox(height: 16),
                      const AppText(
                        text: "No split history found",
                        textStyle: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<SplitHistoryCubit>().fetchHistory(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.splits.length,
                  separatorBuilder: (_, __) => const AppSizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final split = state.splits[index];
                    final isOrganizer = split.userId == currentUserId;

                    return _SplitHistoryCard(
                      split: split,
                      isOrganizer: isOrganizer,
                    );
                  },
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _SplitHistoryCard extends StatelessWidget {
  final SplitRequestModel split;
  final bool isOrganizer;

  const _SplitHistoryCard({
    required this.split,
    required this.isOrganizer,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        split.status == 'settled' ? Colors.green : AppColors.primaryDarkGreen;

    // Calculate pending count
    final pendingCount = split.members.where((m) => !m.isReceived).length;
    final totalCount = split.members.length;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.splitOverview,
          arguments: split.bookingId,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOrganizer
                        ? AppColors.primaryDarkGreen.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOrganizer
                        ? Icons.payments_outlined
                        : Icons.input_outlined,
                    color:
                        isOrganizer ? AppColors.primaryDarkGreen : Colors.blue,
                    size: 20,
                  ),
                ),
                const AppSizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: isOrganizer ? "Collecting Money" : "Paying Share",
                        textStyle: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const AppSizedBox(height: 2),
                      AppText(
                        text:
                            "Booking ID: ${split.bookingId.substring(0, 10)}...",
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      text: "₹${split.totalAmount.toStringAsFixed(0)}",
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                    AppText(
                      text: DateFormat('MMM dd, yyyy').format(split.createdAt!),
                      textStyle: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const AppSizedBox(height: 16),
            const Divider(height: 1),
            const AppSizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    text: split.status.toString(),
                    textStyle: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isOrganizer && split.status != 'settled')
                  AppText(
                    text: "$pendingCount/$totalCount Pending",
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Row(
                  children: [
                    AppText(
                      text: "View Details",
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryDarkGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
