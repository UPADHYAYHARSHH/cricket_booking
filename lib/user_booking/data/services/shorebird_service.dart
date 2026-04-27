import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdService {
  static final _shorebirdCodePush = ShorebirdCodePush();

  /// Checks for updates and downloads them in the background.
  /// Updates will be applied on the next app restart.
  static Future<void> checkForUpdates() async {
    // Only run on physical devices (Shorebird doesn't support emulators/simulators)
    if (kIsWeb) return;
    
    try {
      debugPrint('[Shorebird] Checking for updates...');
      final isUpdateAvailable = await _shorebirdCodePush.isNewPatchAvailableForDownload();
      
      if (isUpdateAvailable) {
        debugPrint('[Shorebird] Update available! Downloading in background...');
        
        // This downloads the update. 
        // Shorebird handles the download and staging automatically.
        await _shorebirdCodePush.downloadUpdateIfAvailable();
        
        debugPrint('[Shorebird] Update downloaded and will be applied on next restart.');
      } else {
        debugPrint('[Shorebird] No updates available.');
      }
    } catch (e) {
      debugPrint('[Shorebird] Error checking for updates: $e');
    }
  }

  /// Returns current patch number if available
  static Future<int?> getCurrentPatchNumber() async {
    if (kIsWeb) return null;
    try {
      return await _shorebirdCodePush.currentPatchNumber();
    } catch (e) {
      return null;
    }
  }
}
