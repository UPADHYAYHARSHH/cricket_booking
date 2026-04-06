import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:bloc_structure/common/constants/colors.dart';

enum ToastType { success, error, warning, info }

class ToastUtil {
  /// Displays a toast message based on the [type] provided.
  /// Standardizes appearance across the app for:
  /// - [ToastType.success]: Green background
  /// - [ToastType.error]: Red background
  /// - [ToastType.warning]: Orange background
  static void show({
    required String message,
    required ToastType type,
  }) {
    Color backgroundColor;
    const Color textColor = AppColors.white;

    switch (type) {
      case ToastType.success:
        backgroundColor = AppColors.success;
        break;
      case ToastType.error:
        backgroundColor = AppColors.error;
        break;
      case ToastType.warning:
        backgroundColor = AppColors.accentOrange;
        break;
      case ToastType.info:
        backgroundColor = AppColors.primaryDarkGreen.withOpacity(0.9);
        break;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 14.0,
    );
  }
}
