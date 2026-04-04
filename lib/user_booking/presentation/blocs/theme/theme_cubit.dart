import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeState {
  final ThemeMode themeMode;

  ThemeState(this.themeMode);
}

class ThemeCubit extends Cubit<ThemeState> {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(ThemeState(ThemeMode.system)) {
    loadTheme();
  }

  void loadTheme() {
    final box = Hive.box(_boxName);
    final themeIndex = box.get(_themeKey, defaultValue: 0); // 0: system, 1: light, 2: dark
    emit(ThemeState(ThemeMode.values[themeIndex]));
  }

  void updateTheme(ThemeMode mode) {
    Hive.box(_boxName).put(_themeKey, mode.index);
    emit(ThemeState(mode));
  }

  void toggleTheme() {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    updateTheme(newMode);
  }
}
