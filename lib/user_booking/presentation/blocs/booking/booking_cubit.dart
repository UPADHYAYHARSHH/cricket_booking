import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/services/analytics_service.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository repository;
  final AnalyticsService analytics;

  BookingCubit(this.repository, this.analytics) : super(BookingInitial());

  Future<void> getBookings() async {
    emit(BookingLoading());
    try {
      final bookings = await repository.getUserBookings();
      analytics.logBookingStarted(groundId: 'all', groundName: 'Fetch My Bookings');
      emit(BookingLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
