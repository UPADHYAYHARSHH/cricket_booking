import 'package:bloc_structure/user_booking/data/models/ground_model.dart';

enum GroundFilter { nearMe, topRated, openNow }

abstract class GroundState {}

class GroundInitial extends GroundState {}

class GroundLoading extends GroundState {}

class GroundLoaded extends GroundState {
  final List<GroundModel> grounds;
  final List<GroundModel> allGrounds;
  final GroundFilter activeFilter;

  GroundLoaded(this.grounds, this.allGrounds, {this.activeFilter = GroundFilter.nearMe});
}

class GroundError extends GroundState {
  final String message;

  GroundError(this.message);
}
