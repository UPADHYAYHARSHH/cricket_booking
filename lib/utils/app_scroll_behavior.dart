import 'package:flutter/material.dart';

class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Disable overscroll glow and stretch animations
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Enforce bouncing scroll physics everywhere
    return const BouncingScrollPhysics();
  }
}
