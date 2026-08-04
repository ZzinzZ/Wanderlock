import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which theme the app renders in.
///
/// Follows the device by default. F1 only needs the toggle to prove every
/// surface repaints; persisting the choice arrives with local storage in F2.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Flips between light and dark. Called while following the system theme,
  /// it moves to the opposite of what is currently on screen, which is what a
  /// user pressing the toggle expects.
  void toggle(Brightness current) {
    state = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
