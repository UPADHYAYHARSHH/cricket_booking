import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro/user_booking/data/models/location_model.dart';
import 'package:turfpro/user_booking/domain/repositories/ground_repository.dart';

abstract class LocationListState {}

class LocationListInitial extends LocationListState {}

class LocationListLoading extends LocationListState {}

class LocationListLoaded extends LocationListState {
  final List<LocationModel> locations;
  LocationListLoaded(this.locations);
}

class LocationListError extends LocationListState {
  final String message;
  LocationListError(this.message);
}

class LocationListCubit extends Cubit<LocationListState> {
  final GroundRepository repository;

  LocationListCubit(this.repository) : super(LocationListInitial());

  Future<void> fetchLocations() async {
    emit(LocationListLoading());
    try {
      final locations = await repository.fetchLocations();
      emit(LocationListLoaded(locations));
    } catch (e) {
      emit(LocationListError(e.toString()));
    }
  }
}
