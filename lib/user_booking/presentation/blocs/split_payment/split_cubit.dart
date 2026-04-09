import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/split_payment_repository.dart';
import '../../../domain/models/split_payment_model.dart';
import 'split_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplitPaymentCubit extends Cubit<SplitPaymentState> {
  final SplitPaymentRepository _repository;

  SplitPaymentCubit(this._repository) : super(SplitPaymentInitial());

  /// Initialize the form for a new booking
  void initForm(double totalAmount) {
    emit(SplitPaymentFormState(
      members: [], // List of teammates, booker not included here
      totalAmount: totalAmount,
      isEqualSplit: true,
    ));
  }

  void addMember(String name) {
    if (state is SplitPaymentFormState) {
      final s = state as SplitPaymentFormState;
      final newMembers = List<SplitMemberModel>.from(s.members);
      
      newMembers.add(SplitMemberModel(name: name, amount: 0));
      
      final updatedMembers = _recalculateAmounts(newMembers, s.totalAmount, s.isEqualSplit);
      emit(s.copyWith(members: updatedMembers));
    }
  }

  void addLinkedMember(String name, String userId) {
    if (state is SplitPaymentFormState) {
      final s = state as SplitPaymentFormState;
      final newMembers = List<SplitMemberModel>.from(s.members);
      
      newMembers.add(SplitMemberModel(name: name, amount: 0, memberUserId: userId));
      
      final updatedMembers = _recalculateAmounts(newMembers, s.totalAmount, s.isEqualSplit);
      emit(s.copyWith(members: updatedMembers));
    }
  }

  void removeMember(int index) {
    if (state is SplitPaymentFormState) {
      final s = state as SplitPaymentFormState;
      final newMembers = List<SplitMemberModel>.from(s.members);
      newMembers.removeAt(index);
      
      final updatedMembers = _recalculateAmounts(newMembers, s.totalAmount, s.isEqualSplit);
      emit(s.copyWith(members: updatedMembers));
    }
  }

  void updateMemberAmount(int index, double amount) {
    if (state is SplitPaymentFormState) {
      final s = state as SplitPaymentFormState;
      final newMembers = List<SplitMemberModel>.from(s.members);
      newMembers[index] = SplitMemberModel(
        name: newMembers[index].name,
        amount: amount,
        isReceived: newMembers[index].isReceived,
      );
      
      emit(s.copyWith(members: newMembers, isEqualSplit: false));
    }
  }

  void toggleSplitMode(bool isEqual) {
    if (state is SplitPaymentFormState) {
      final s = state as SplitPaymentFormState;
      final updatedMembers = _recalculateAmounts(s.members, s.totalAmount, isEqual);
      emit(s.copyWith(isEqualSplit: isEqual, members: updatedMembers));
    }
  }

  void updateUpiId(String upiId) {
    if (state is SplitPaymentFormState) {
      final s = state as SplitPaymentFormState;
      emit(s.copyWith(upiId: upiId));
    }
  }

  void updateQrImage(File? image) {
    if (state is SplitPaymentFormState) {
      final s = state as SplitPaymentFormState;
      emit(s.copyWith(qrImage: image));
    }
  }

  List<SplitMemberModel> _recalculateAmounts(
      List<SplitMemberModel> members, double totalAmount, bool isEqual) {
    if (!isEqual) return members;
    
    // totalAmount / (teammates + booker)
    final share = totalAmount / (members.length + 1);
    return members.map((m) => SplitMemberModel(
      name: m.name,
      amount: double.parse(share.toStringAsFixed(2)),
      isReceived: m.isReceived,
    )).toList();
  }

  Future<void> submitSplit(String bookingId) async {
    if (state is SplitPaymentFormState) {
      final s = state as SplitPaymentFormState;
      emit(s.copyWith(isSubmitting: true));

      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final request = SplitRequestModel(
          bookingId: bookingId,
          userId: userId,
          totalAmount: s.totalAmount,
          upiId: s.upiId,
          status: SplitStatus.pending,
        );

        final requestId = await _repository.createSplitRequest(
          request: request,
          members: s.members,
          qrImage: s.qrImage,
        );

        emit(SplitPaymentSuccess(requestId));
      } catch (e) {
        emit(SplitPaymentError(e.toString()));
        // Recover form state
        emit(s.copyWith(isSubmitting: false));
      }
    }
  }

  /// Load existing split for overview
  Future<void> loadSplitOverview(String bookingId) async {
    emit(SplitPaymentLoading());
    try {
      final split = await _repository.getSplitForBooking(bookingId);
      if (split != null) {
        emit(SplitPaymentOverviewLoaded(split));
      } else {
        emit(SplitPaymentError("No split found for this booking"));
      }
    } catch (e) {
      emit(SplitPaymentError(e.toString()));
    }
  }

  Future<void> toggleMemberReceived(String memberId, bool received) async {
    if (state is SplitPaymentOverviewLoaded) {
      final s = state as SplitPaymentOverviewLoaded;
      emit(SplitPaymentOverviewLoaded(s.splitRequest, isUpdating: true));
      
      try {
        await _repository.updateMemberStatus(memberId, received);
        
        // Refresh local state
        final updatedMembers = s.splitRequest.members.map((m) {
          if (m.id == memberId) {
            return SplitMemberModel(
              id: m.id,
              splitRequestId: m.splitRequestId,
              name: m.name,
              amount: m.amount,
              isReceived: received,
            );
          }
          return m;
        }).toList();

        final updatedRequest = SplitRequestModel(
          id: s.splitRequest.id,
          bookingId: s.splitRequest.bookingId,
          userId: s.splitRequest.userId,
          totalAmount: s.splitRequest.totalAmount,
          upiId: s.splitRequest.upiId,
          qrCodeUrl: s.splitRequest.qrCodeUrl,
          status: s.splitRequest.status,
          createdAt: s.splitRequest.createdAt,
          members: updatedMembers,
        );

        emit(SplitPaymentOverviewLoaded(updatedRequest));
      } catch (e) {
        emit(SplitPaymentError(e.toString()));
        emit(SplitPaymentOverviewLoaded(s.splitRequest));
      }
    }
  }
}
