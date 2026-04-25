import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playNotificationSound(String type) async {
    String soundPath;
    
    switch (type) {
      case 'booking_confirmed':
        soundPath = 'assets/sounds/success.mp3';
        break;
      case 'booking_cancelled':
        soundPath = 'assets/sounds/error.mp3';
        break;
      case 'payment_received':
      case 'split_payment':
        soundPath = 'assets/sounds/cash.mp3';
        break;
      case 'loyalty_points':
        soundPath = 'assets/sounds/coins.mp3';
        break;
      case 'reminder':
        soundPath = 'assets/sounds/ping.mp3';
        break;
      case 'promotion':
        soundPath = 'assets/sounds/gift.mp3';
        break;
      default:
        soundPath = 'assets/sounds/notification.mp3';
    }

    try {
      // Guard: Check if asset exists before playing to avoid crashes/errors
      final assetPath = soundPath.replaceFirst('assets/', '');
      
      // We can use rootBundle to check if the asset is actually bundled
      try {
        await rootBundle.load(soundPath);
        await _player.play(AssetSource(assetPath));
      } catch (_) {
        // Asset not found, fail silently as requested
        return;
      }
    } catch (e) {
      // Silently fail as requested
    }
  }

  void dispose() {
    _player.dispose();
  }
}
