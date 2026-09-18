import 'package:flutter/material.dart';
import 'package:turfpro/user_booking/data/models/location_model.dart';
import 'package:turfpro/user_booking/presentation/widgets/saved_location_card.dart';

class LocationCard extends StatelessWidget {
  final LocationModel location;
  final bool showAmenities;
  final bool isGrid;
  final VoidCallback? onUnfavorite;

  const LocationCard({
    super.key,
    required this.location,
    this.showAmenities = true,
    this.isGrid = false,
    this.onUnfavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SavedLocationCard(
      location: location,
      onUnfavorite: onUnfavorite,
    );
  }
}

