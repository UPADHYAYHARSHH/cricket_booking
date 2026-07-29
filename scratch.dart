import 'dart:io';
void main() {
  final path = 'E:/rutvik/projects/box_cricket/booking_app/lib/user_booking/presentation/screens/category_grounds/category_grounds_screen.dart';
  var content = File(path).readAsStringSync();
  
  content = content.replaceAll(
    "import 'package:turfpro/user_booking/presentation/widgets/ground_card.dart';",
    "import 'package:turfpro/user_booking/presentation/widgets/venue_card.dart';\nimport 'package:turfpro/user_booking/data/models/venue_model.dart';"
  );
  
  content = content.replaceAll(
    "List<GroundModel> _applyLocalFilters(List<GroundModel> baseGrounds, double? userLat, double? userLng) {",
    "List<VenueModel> _applyLocalFilters(List<VenueModel> baseVenues, double? userLat, double? userLng) {"
  );
  content = content.replaceAll(
    "List<GroundModel> filtered = List.from(baseGrounds);",
    "List<VenueModel> filtered = List.from(baseVenues);"
  );
  content = content.replaceAll(
    "filtered = filtered.where((g) => g.pricePerHour >= _criteria.minPrice && g.pricePerHour <= _criteria.maxPrice).toList();",
    "filtered = filtered.where((v) { final p = v.pitches.first; return p.pricePerHour >= _criteria.minPrice && p.pricePerHour <= _criteria.maxPrice; }).toList();"
  );
  content = content.replaceAll(
    "g.amenities.any((ga) => ga.toLowerCase() == amenity.toLowerCase())",
    "v.pitches.first.amenities.any((pa) => pa.toLowerCase() == amenity.toLowerCase())"
  );
  content = content.replaceAll(
    "filtered = filtered.where((g) {",
    "filtered = filtered.where((v) {"
  );
  content = content.replaceAll(
    "filtered = filtered.where((g) => _isAvailableNow(g.openingTime, g.closingTime)).toList();",
    "filtered = filtered.where((v) => _isAvailableNow(v.pitches.first.openingTime, v.pitches.first.closingTime)).toList();"
  );
  content = content.replaceAll(
    "filtered = filtered.where((g) => _calculateDistance(userLat, userLng, g.latitude, g.longitude) <= 10.0).toList();",
    "filtered = filtered.where((v) => _calculateDistance(userLat, userLng, v.latitude, v.longitude) <= 10.0).toList();"
  );
  content = content.replaceAll(
    "filtered = filtered.where((g) => g.rating >= 4.0).toList();",
    "filtered = filtered.where((v) => v.rating >= 4.0).toList();"
  );
  content = content.replaceAll(
    "filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));",
    "filtered.sort((a, b) => a.pitches.first.pricePerHour.compareTo(b.pitches.first.pricePerHour));"
  );
  content = content.replaceAll(
    "filtered.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));",
    "filtered.sort((a, b) => b.pitches.first.pricePerHour.compareTo(a.pitches.first.pricePerHour));"
  );

  content = content.replaceAll(
    "final baseCategoryGrounds = state.grounds.where((g) {",
    "final baseCategoryVenues = state.venues.where((v) {"
  );
  content = content.replaceAll(
    "final matchesCategory = g.categories.any((c) {",
    "final matchesCategory = v.availableSports.any((c) {"
  );
  content = content.replaceAll(
    "g.city.toLowerCase().contains(city) ||",
    "v.pitches.first.city.toLowerCase().contains(city) ||"
  );
  content = content.replaceAll(
    "city.contains(g.city.toLowerCase());",
    "city.contains(v.pitches.first.city.toLowerCase());"
  );
  
  content = content.replaceAll(
    "final filteredGrounds = _applyLocalFilters(",
    "final filteredVenues = _applyLocalFilters("
  );
  content = content.replaceAll(
    "baseCategoryGrounds,",
    "baseCategoryVenues,"
  );
  content = content.replaceAll(
    "if (filteredGrounds.isEmpty) {",
    "if (filteredVenues.isEmpty) {"
  );
  content = content.replaceAll(
    "itemCount: filteredGrounds.length,",
    "itemCount: filteredVenues.length,"
  );
  content = content.replaceAll(
    "child: GroundCard(ground: filteredGrounds[index]),",
    "child: VenueCard(venue: filteredVenues[index], showAmenities: true, isGrid: false),"
  );
  
  File(path).writeAsStringSync(content);
  print('Done!');
}
