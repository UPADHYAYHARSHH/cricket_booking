import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/data/models/venue_model.dart';
import 'package:turfpro/user_booking/domain/models/filter_criteria.dart';

abstract class GroundState {}

class GroundInitial extends GroundState {}

class GroundLoading extends GroundState {}

class GroundLoaded extends GroundState {
  final List<GroundModel> grounds;
  final List<GroundModel> allGrounds;
  final List<VenueModel> venues;
  final List<VenueModel> allVenues;
  final FilterCriteria criteria;

  GroundLoaded(this.grounds, this.allGrounds, {required this.criteria, this.venues = const [], this.allVenues = const []});
}

class GroundError extends GroundState {
  final String message;

  GroundError(this.message);
}