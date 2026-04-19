import '../../data/models/loyalty_point_model.dart';

abstract class LoyaltyRepository {
  /// Fetches total non-expired and unused points for the current user.
  Future<int> fetchTotalAvailablePoints();

  /// Redeems points (FIFO basis - using oldest points first).
  Future<void> redeemPoints(int pointsToUse);

  /// Earns new points (valid for 6 months).
  Future<void> earnPoints(int pointsEarned);

  /// Get list of points with expiry for a detailed view.
  Future<List<LoyaltyPointModel>> fetchPointsHistory();
}
