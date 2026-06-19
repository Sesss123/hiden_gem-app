import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_mode_provider.g.dart';

@riverpod
class AppModeNotifier extends _$AppModeNotifier {
  @override
  ThemeMode build() => ThemeMode.dark;

  void setMode(ThemeMode mode) {
    state = mode;
  }
}
