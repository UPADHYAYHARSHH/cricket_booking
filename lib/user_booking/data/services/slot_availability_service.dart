import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro/user_booking/data/models/ground_model.dart';
import 'package:turfpro/user_booking/data/models/venue_model.dart';

class SlotAvailabilityService {
  /// Converts any time representation (24h, 12h AM/PM, ISO timestamp) into minutes from midnight (0..1439).
  static int? parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final str = timeStr.trim();

    // Check if ISO 8601 string (e.g., 2026-10-28T18:00:00)
    if (str.contains('T')) {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        final local = dt.toLocal();
        return local.hour * 60 + local.minute;
      }
    }

    final upper = str.toUpperCase();
    final isPm = upper.contains('PM');
    final isAm = upper.contains('AM');

    // Strip out AM/PM and trim
    final clean = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = clean.split(':');
    if (parts.isEmpty) return null;

    int? hour = int.tryParse(parts[0]);
    if (hour == null) return null;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    if (isPm && hour != 12) {
      hour += 12;
    } else if (isAm && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }

  /// Determines if two time intervals [start1, end1] and [start2, end2] in minutes overlap.
  static bool hasOverlap(int start1, int end1, int start2, int end2) {
    return max(start1, start2) < min(end1, end2);
  }

  /// Queries Supabase to find all ground IDs that have conflicting bookings or booked/blocked slots
  /// for the selected date and time range.
  static Future<Set<String>> getBookedGroundIds({
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final reqStartMins = startTime.hour * 60 + startTime.minute;
    var reqEndMins = endTime.hour * 60 + endTime.minute;

    // Handle overnight slot filter (e.g. 11 PM to 1 AM)
    if (reqEndMins <= reqStartMins) {
      reqEndMins += 1440;
    }

    final unavailableGroundIds = <String>{};

    // 1. Check 'slots' table for this date
    try {
      final slotsRes = await Supabase.instance.client
          .from('slots')
          .select('ground_id, start_time, end_time, status')
          .eq('date', formattedDate);

      for (final row in (slotsRes as List)) {
        final status = (row['status'] ?? '').toString().toLowerCase();
        if (status == 'booked' ||
            status == 'blocked' ||
            status == 'requested' ||
            status == 'held') {
          final groundId = row['ground_id']?.toString();
          if (groundId == null || groundId.isEmpty) continue;

          final startStr = row['start_time']?.toString() ?? '';
          final endStr = row['end_time']?.toString() ?? '';

          final slotStartMins = parseTimeToMinutes(startStr);
          if (slotStartMins == null) continue;

          int slotEndMins;
          final parsedEnd = parseTimeToMinutes(endStr);
          if (parsedEnd != null && parsedEnd > slotStartMins) {
            slotEndMins = parsedEnd;
          } else {
            // Default 60-minute slot duration
            slotEndMins = slotStartMins + 60;
          }

          if (hasOverlap(reqStartMins, reqEndMins, slotStartMins, slotEndMins)) {
            unavailableGroundIds.add(groundId);
          }
        }
      }
    } catch (e) {
      debugPrint('[SlotAvailabilityService] Error querying slots table: $e');
    }

    // 2. Check 'bookings' table for this date
    try {
      final searchStart = DateTime(date.year, date.month, date.day)
          .subtract(const Duration(hours: 12))
          .toIso8601String();
      final searchEnd = DateTime(date.year, date.month, date.day, 23, 59, 59)
          .add(const Duration(hours: 12))
          .toIso8601String();

      final bookingsRes = await Supabase.instance.client
          .from('bookings')
          .select('ground_id, slot_time, period, status')
          .gte('slot_time', searchStart)
          .lte('slot_time', searchEnd)
          .not('status', 'in', '("cancelled", "failed")');

      for (final row in (bookingsRes as List)) {
        final groundId = row['ground_id']?.toString();
        if (groundId == null || groundId.isEmpty) continue;

        final periodStr = row['period']?.toString() ?? '';
        final slotTimeStr = row['slot_time']?.toString();

        if (periodStr.contains('|')) {
          final slotParts = periodStr.split('|').last.split(',');
          for (final part in slotParts) {
            final startMins = parseTimeToMinutes(part.trim());
            if (startMins != null) {
              if (hasOverlap(reqStartMins, reqEndMins, startMins, startMins + 60)) {
                unavailableGroundIds.add(groundId);
                break;
              }
            }
          }
        } else if (slotTimeStr != null) {
          final dt = DateTime.tryParse(slotTimeStr);
          if (dt != null) {
            final localDt = dt.toLocal();
            if (localDt.year == date.year &&
                localDt.month == date.month &&
                localDt.day == date.day) {
              final startMins = localDt.hour * 60 + localDt.minute;
              if (hasOverlap(reqStartMins, reqEndMins, startMins, startMins + 60)) {
                unavailableGroundIds.add(groundId);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SlotAvailabilityService] Error querying bookings table: $e');
    }

    return unavailableGroundIds;
  }

  /// Verifies if a ground is open on the given date and whether its operating hours
  /// cover the requested time window.
  static bool isGroundOperating({
    required GroundModel ground,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    // 1. Operating days check (Monday = 1, Sunday = 7)
    if (ground.operatingDays.isNotEmpty &&
        !ground.operatingDays.contains(date.weekday)) {
      return false;
    }

    // 2. Active status flag
    if (!ground.isAvailable) {
      return false;
    }

    // 3. Operating hours check
    final openMins = parseTimeToMinutes(ground.openingTime);
    final closeMins = parseTimeToMinutes(ground.closingTime);

    if (openMins == null || closeMins == null) {
      return true; // No explicit hours configured
    }

    int reqStartMins = startTime.hour * 60 + startTime.minute;
    int reqEndMins = endTime.hour * 60 + endTime.minute;

    if (openMins <= closeMins) {
      // Normal daytime hours (e.g. 06:00 to 23:00)
      return reqStartMins >= openMins && reqEndMins <= closeMins;
    } else {
      // Overnight hours (e.g. 18:00 to 02:00)
      final effectiveClose = closeMins + 1440;
      if (reqStartMins < openMins && reqStartMins <= closeMins) {
        reqStartMins += 1440;
      }
      if (reqEndMins < openMins && reqEndMins <= closeMins) {
        reqEndMins += 1440;
      }
      return reqStartMins >= openMins && reqEndMins <= effectiveClose;
    }
  }

  /// Checks if a single ground is available for the given slot on that date.
  static bool isGroundAvailable({
    required GroundModel ground,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Set<String> unavailableGroundIds,
  }) {
    if (unavailableGroundIds.contains(ground.id)) {
      return false;
    }
    return isGroundOperating(
      ground: ground,
      date: date,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Checks if a venue is available (i.e. at least one of its pitches is available).
  static bool isVenueAvailable({
    required VenueModel venue,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Set<String> unavailableGroundIds,
  }) {
    return venue.pitches.any((pitch) => isGroundAvailable(
          ground: pitch,
          date: date,
          startTime: startTime,
          endTime: endTime,
          unavailableGroundIds: unavailableGroundIds,
        ));
  }
}
