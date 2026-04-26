import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro/user_booking/constants/route_constants.dart';
import 'package:turfpro/user_booking/di/get_it/get_it.dart';
import 'package:turfpro/user_booking/domain/repositories/ground_repository.dart';
import 'package:turfpro/main.dart'; // Import to access navigatorKey

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingGroundId;

  void init() {
    _appLinks = AppLinks();
    _handleIncomingLinks();
    _handleInitialLink();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        if (_pendingGroundId != null) {
          debugPrint('Auth signed in, processing pending ground: $_pendingGroundId');
          _navigateToGround(_pendingGroundId!);
          clearPendingGroundId();
        }
      }
    });
  }

  String? get pendingGroundId => _pendingGroundId;

  void clearPendingGroundId() {
    _pendingGroundId = null;
  }

  Future<void> _handleInitialLink() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _processLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error handling initial link: $e');
    }
  }

  void _handleIncomingLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _processLink(uri);
    }, onError: (err) {
      debugPrint('Error in link stream: $err');
    });
  }

  void _processLink(Uri uri) {
    debugPrint('Processing Deep Link: $uri');
    
    // Example URL: https://turfpro-web.vercel.app/ground?id=123
    if (uri.path.contains('/ground')) {
      final id = uri.queryParameters['id'];
      if (id != null) {
        _handleGroundLink(id);
      }
    }
  }

  Future<void> _handleGroundLink(String id) async {
    final user = Supabase.instance.client.auth.currentUser;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (user == null) {
      // Not logged in, store the ID and redirect to login
      _pendingGroundId = id;
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }

    // Logged in, fetch ground and navigate
    _navigateToGround(id);
  }

  Future<void> _navigateToGround(String id) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final groundRepo = getIt<GroundRepository>();
      final ground = await groundRepo.fetchGroundById(id);

      if (context.mounted) {
        Navigator.pop(context); // Pop loading

        if (ground != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.slotSelection,
            arguments: ground,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ground not found')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ground: $e')),
        );
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
