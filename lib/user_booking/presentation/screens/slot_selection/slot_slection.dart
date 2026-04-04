import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/domain/models/slot_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bloc_structure/user_booking/presentation/blocs/saved_ground/saved_ground_cubit.dart';
import '../../../constants/route_constants.dart';
import '../../widgets/slot_selection_widgets.dart';
import '../../../data/models/ground_model.dart';
import '../../blocs/slot_selection/slot_selection_cubit.dart';
import '../../blocs/slot_selection/slot_selection_state.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  GroundModel? _ground;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is GroundModel) {
        _ground = args;
        // Initial load for today
        context.read<SlotSelectionCubit>().loadSlots(
              _ground!.id,
              DateTime.now(),
              openingTime: _ground!.openingTime,
              closingTime: _ground!.closingTime,
              pricePerSlot: _ground!.pricePerHour.toDouble(),
            );
      }
      _isInitialized = true;
    }
  }

  void _onConfirmBooking(
      double totalPrice, dynamic activeDate, dynamic selectedSlots) {
    if (selectedSlots.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(
          text: 'Booking confirmed for ${selectedSlots.length} slot(s)!',
          textStyle: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.accentOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pushReplacementNamed(
        context, AppRoutes.bookingConfirmationScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
        builder: (context, state) {
          final selectedSlots = state.slots
              .where((s) => s.status == SlotStatus.selected)
              .toList();
          final totalPrice =
              selectedSlots.fold<double>(0, (sum, s) => sum + s.price);
          final activeDate = state.dates.firstWhere((d) => d.isSelected);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlocBuilder<SavedGroundCubit, SavedGroundState>(
                          builder: (context, state) {
                        final isSaved = _ground != null &&
                            state.favoriteIds.contains(_ground!.id);
                        return SlotSelectionWidgets.buildHeader(
                          context,
                          _ground,
                          isSaved: isSaved,
                          onToggleFav: () {
                            final user =
                                Supabase.instance.client.auth.currentUser;
                            if (user != null && _ground != null) {
                              context
                                  .read<SavedGroundCubit>()
                                  .toggleFavorite(user.id, _ground!.id);
                            } else if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: AppText(
                                        text: "Please login to save grounds")),
                              );
                            }
                          },
                        );
                      }),
                      SlotSelectionWidgets.buildTurfImage(_ground),
                      SlotSelectionWidgets.buildDateSelector(state.dates,
                          (index) {
                        if (_ground != null) {
                          context.read<SlotSelectionCubit>().selectDate(
                                index,
                                _ground!.id,
                                openingTime: _ground!.openingTime,
                                closingTime: _ground!.closingTime,
                                pricePerSlot: _ground!.pricePerHour.toDouble(),
                              );
                        }
                      }),
                      SlotSelectionWidgets.buildDescriptionSection(
                          _ground?.description),
                      SlotSelectionWidgets.buildAmenitiesSection(
                          _ground?.amenities),
                      if (_ground != null)
                        SlotSelectionWidgets.buildMapSection(_ground!),
                      if (state.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accentOrange)),
                        )
                      else if (state.errorMessage != null)
                        Center(
                            child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: AppText(text: state.errorMessage!),
                        ))
                      else ...[
                        SlotSelectionWidgets.buildLegend(),
                        SlotSelectionWidgets.buildSlotSection(state.slots,
                            (index) {
                          context.read<SlotSelectionCubit>().toggleSlot(index);
                        }),
                        const AppSizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              SlotSelectionWidgets.buildBottomBar(
                selectedSlots,
                activeDate,
                totalPrice,
                () => _onConfirmBooking(totalPrice, activeDate, selectedSlots),
              ),
            ],
          );
        },
      ),
    );
  }
}
