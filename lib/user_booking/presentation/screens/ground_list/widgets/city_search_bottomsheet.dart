import 'dart:async';
import 'dart:convert';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro/common/constants/colors.dart';
import 'package:turfpro/user_booking/constants/widgets/app_text.dart';
import 'package:turfpro/user_booking/constants/widgets/app_sizedBox.dart';

import '../../../blocs/location/location_cubit.dart';

class CitySearchBottomSheet extends StatefulWidget {
  const CitySearchBottomSheet({super.key});

  @override
  State<CitySearchBottomSheet> createState() => _CitySearchBottomSheetState();
}

class _CitySearchBottomSheetState extends State<CitySearchBottomSheet> {
  final TextEditingController controller = TextEditingController();
  // List of search results from Google Places API
  List<Map<String, dynamic>> results = [];
  // List of previously searched cities loaded from Hive (stored as JSON)
  List<Map<String, dynamic>> history = [];
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
      history = historyBox.values.map((e) {
        try {
          return json.decode(e) as Map<String, dynamic>;
        } catch (_) {
          return {'name': e}; // Fallback for old simple strings
        }
      }).toList().reversed.toList();
    });
  }

  Timer? _debounce;

  /// FETCH CITIES FROM OPEN-METEO GEOCODING API (Free)
  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    final url = "https://geocoding-api.open-meteo.com/v1/search"
        "?name=$query"
        "&count=10"
        "&language=en"
        "&format=json";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final res = data['results'] as List?;

      if (res == null) return [];

      final List<Map<String, dynamic>> cityResults = [];
      for (var e in res) {
        if (e['country_code'] == 'IN') {
          // Only India
          final cityName = e['name'] as String? ?? "";
          final stateName = e['admin1'] as String? ?? "";
          final lat = (e['latitude'] as num?)?.toDouble();
          final lng = (e['longitude'] as num?)?.toDouble();

          final formatString = stateName.isNotEmpty && stateName != cityName
              ? "$cityName, $stateName"
              : cityName;

          if (!cityResults.any((element) => element['name'] == formatString) && formatString.isNotEmpty) {
            cityResults.add({
              'name': formatString,
              'lat': lat,
              'lng': lng,
            });
          }
        }
      }
      return cityResults;
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
  void selectCity(Map<String, dynamic> cityData) async {
    final String cityLabel = cityData['name'];
    
    debugPrint("[CITY_SEARCH] Selecting city: $cityLabel with coords: ${cityData['lat']}, ${cityData['lng']}");

    // Check for duplicates by name in history
    int existingIndex = -1;
    final List<String> currentValues = historyBox.values.toList();
    for (int i = 0; i < currentValues.length; i++) {
      try {
        final Map<String, dynamic> map = json.decode(currentValues[i]);
        if (map['name'] == cityLabel) {
          existingIndex = i;
          break;
        }
      } catch (_) {
        if (currentValues[i] == cityLabel) {
          existingIndex = i;
          break;
        }
      }
    }

    // Remove old entry if exists to move it to top
    if (existingIndex != -1) {
      await historyBox.deleteAt(existingIndex);
    } else if (historyBox.length >= 5) {
      await historyBox.deleteAt(0); // Maintain only top 5 history items
    }

    // Add new entry as JSON
    await historyBox.add(json.encode(cityData));

    if (mounted) {
      // Update global LocationCubit state and navigate back
      context.read<LocationCubit>().setCity(
        cityLabel,
        lat: cityData['lat'],
        lng: cityData['lng'],
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.85),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Search city...",
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      ),
                      // prefixIcon: HugeIcon(
                      //   icon: HugeIcons.strokeRoundedSearch01,
                      //   size: 10,
                      //   color: Theme.of(context)
                      //       .colorScheme
                      //       .onSurface
                      //       .withOpacity(0.4),
                      // ),
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
        ));
  }

  Widget _buildHistory() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: EdgeInsets.zero,
      children: history.map((cityData) {
        final String city = cityData['name'] ?? "";
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
          onTap: () => selectCity(cityData),
        );
      }).toList(),
    );
  }

  Widget _buildResults() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ListView(
      padding: EdgeInsets.zero,
      children: results.map((cityData) {
        final String city = cityData['name'] ?? "";
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
          onTap: () => selectCity(cityData),
        );
      }).toList(),
    );
  }
}
