import 'package:flutter/material.dart';

class UIHelpers {
  static double w(BuildContext context, double size) {
    return MediaQuery.of(context).size.width * (size / 375);
  }

  static double h(BuildContext context, double size) {
    return MediaQuery.of(context).size.height * (size / 812);
  }
}
