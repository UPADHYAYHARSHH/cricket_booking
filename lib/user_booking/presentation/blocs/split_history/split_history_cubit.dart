import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/split_payment_repository.dart';
import '../../../domain/models/split_payment_model.dart';

abstract class SplitHistoryState {}

class SplitHistoryInitial extends SplitHistoryState {}

class SplitHistoryLoading extends SplitHistoryState {}

class SplitHistoryLoaded extends SplitHistoryState {
  final List<SplitRequestModel> splits;
  SplitHistoryLoaded(this.splits);
}

class SplitHistoryError extends SplitHistoryState {
  final String message;
  SplitHistoryError(this.message);
}

class SplitHistoryCubit extends Cubit<SplitHistoryState> {
  final SplitPaymentRepository repository;

  SplitHistoryCubit(this.repository) : super(SplitHistoryInitial());

  Future<void> fetchHistory() async {
    emit(SplitHistoryLoading());
    try {
      final splits = await repository.getUserSplits();
      emit(SplitHistoryLoaded(splits));
    } catch (e) {
      emit(SplitHistoryError(e.toString()));
    }
  }
}
