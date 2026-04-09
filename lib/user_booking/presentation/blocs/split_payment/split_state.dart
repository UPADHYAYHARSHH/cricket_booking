import 'dart:io';
import '../../../domain/models/split_payment_model.dart';

abstract class SplitPaymentState {}

class SplitPaymentInitial extends SplitPaymentState {}

class SplitPaymentLoading extends SplitPaymentState {}

class SplitPaymentSuccess extends SplitPaymentState {
  final String requestId;
  SplitPaymentSuccess(this.requestId);
}

class SplitPaymentError extends SplitPaymentState {
  final String message;
  SplitPaymentError(this.message);
}

class SplitPaymentFormState extends SplitPaymentState {
  final List<SplitMemberModel> members;
  final double totalAmount;
  final bool isEqualSplit;
  final String upiId;
  final File? qrImage;
  final String? qrUrl;
  final bool isSubmitting;

  SplitPaymentFormState({
    required this.members,
    required this.totalAmount,
    this.isEqualSplit = true,
    this.upiId = '',
    this.qrImage,
    this.qrUrl,
    this.isSubmitting = false,
  });

  SplitPaymentFormState copyWith({
    List<SplitMemberModel>? members,
    double? totalAmount,
    bool? isEqualSplit,
    String? upiId,
    File? qrImage,
    String? qrUrl,
    bool? isSubmitting,
  }) {
    return SplitPaymentFormState(
      members: members ?? this.members,
      totalAmount: totalAmount ?? this.totalAmount,
      isEqualSplit: isEqualSplit ?? this.isEqualSplit,
      upiId: upiId ?? this.upiId,
      qrImage: qrImage ?? this.qrImage,
      qrUrl: qrUrl ?? this.qrUrl,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class SplitPaymentOverviewLoaded extends SplitPaymentState {
  final SplitRequestModel splitRequest;
  final bool isUpdating;

  SplitPaymentOverviewLoaded(this.splitRequest, {this.isUpdating = false});
}
