import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:bloc_structure/common/constants/colors.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_text.dart';
import 'package:bloc_structure/user_booking/constants/widgets/app_sizedBox.dart';

import '../../../blocs/location/location_cubit.dart';

class CitySearchBottomSheet extends StatefulWidget {
  const CitySearchBottomSheet({super.key});

  @override
  State<CitySearchBottomSheet> createState() => _CitySearchBottomSheetState();
}

class _CitySearchBottomSheetState extends State<CitySearchBottomSheet> {
  final TextEditingController controller = TextEditingController();
  // List of search results from Google Places API
  List<String> results = [];
  // List of previously searched cities loaded from Hive
  List<String> history = [];
  // Loading state for the search API call
  bool isLoading = false;
  // Hive box for persistent city search history
  late Box<String> historyBox;

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  void _initHistory() async {
    historyBox = await Hive.openBox<String>('city_history');
    setState(() {
      history = historyBox.values.toList().reversed.toList();
    });
  }

  Timer? _debounce;

  /// FETCH CITIES FROM GOOGLE PLACES API
  Future<List<String>> searchCities(String query) async {
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=$query"
        "&types=(cities)"
        "&components=country:in"
        "&key=AIzaSyAMODBdO75JmBy6yW-rIYHQyuwpc34nsh4";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final predictions = data['predictions'] as List;

      return predictions.map((e) {
        final mainText = e['structured_formatting']['main_text'] as String;
        final secondaryText =
            e['structured_formatting']['secondary_text'] as String? ?? "";

        // Extract only the state/area (usually the first part of secondary_text)
        final state = secondaryText.split(',').first.trim();

        return state.isNotEmpty ? "$mainText, $state" : mainText;
      }).toList();
    } else {
      throw Exception("Failed to fetch cities");
    }
  }

  /// HANDLE SEARCH QUERY WITH DEBOUNCING
  void onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        results = [];
        isLoading = false;
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() => isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final res = await searchCities(query);
        setState(() {
          results = res;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
      }
    });
  }

  /// SELECT CITY, SAVE TO HISTORY, AND UPDATE CUBIT
  void selectCity(String cityLabel) async {
    // Save to Hive persistent storage
    if (!historyBox.values.contains(cityLabel)) {
      if (historyBox.length >= 5) {
        await historyBox.deleteAt(0); // Maintain only top 5 history items
      }
      await historyBox.add(cityLabel);
    } else {
      // If already exists, move to top
      final index = historyBox.values.toList().indexOf(cityLabel);
      await historyBox.deleteAt(index);
      await historyBox.add(cityLabel);
    }

    if (mounted) {
      // Update global LocationCubit state and navigate back
      // Extract the city name before the comma if needed for specific logic,
      // but for UX we can show the full label.
      context.read<LocationCubit>().setCity(cityLabel);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        height: 500,
        child: Column(
          children: [
            const AppSizedBox(height: 10),

            /// Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const AppSizedBox(height: 16),

            /// Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                onChanged: onSearch,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: "Search city...",
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const AppSizedBox(height: 16),

            /// Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (controller.text.isEmpty
                      ? _buildHistory()
                      : _buildResults()),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: EdgeInsets.zero,
      children: history.map((city) {
        final parts = city.split(',');
        final mainCity = parts[0].trim();
        final secondary =
            parts.length > 1 ? parts.sublist(1).join(',').trim() : "";

        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              color: onSurface.withOpacity(0.3),
              size: 20,
            ),
          ),
          title: AppText(
            text: mainCity,
            weight: FontWeight.w500,
          ),
          subtitle: secondary.isNotEmpty
              ? AppText(
                  text: secondary,
                  size: 12,
                  color: onSurface.withOpacity(0.5),
                )
              : null,
          onTap: () => selectCity(city),
        );
      }).toList(),
    );
  }

  Widget _buildResults() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: EdgeInsets.zero,
      children: results.map((city) {
        final parts = city.split(',');
        final mainCity = parts[0].trim();
        final secondary =
            parts.length > 1 ? parts.sublist(1).join(',').trim() : "";

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const HugeIcon(
            icon: HugeIcons.strokeRoundedLocation01,
            color: AppColors.primaryDarkGreen,
            size: 22,
          ),
          title: AppText(
            text: mainCity,
            weight: FontWeight.w500,
          ),
          subtitle: secondary.isNotEmpty
              ? AppText(
                  text: secondary,
                  size: 12,
                  color: onSurface.withOpacity(0.5),
                )
              : null,
          onTap: () => selectCity(city),
        );
      }).toList(),
    );
  }
}
