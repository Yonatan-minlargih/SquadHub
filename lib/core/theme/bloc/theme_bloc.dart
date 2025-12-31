import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/theme_service.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeService _themeService = ThemeService();

  ThemeBloc() : super(const ThemeState(themeMode: ThemeMode.system)) {
    on<ThemeChanged>(_onThemeChanged);
    on<ThemeToggled>(_onThemeToggled);
    on<ThemeLoad>(_onThemeLoad);
    // Load theme on initialization
    add(const ThemeLoad());
  }

  Future<void> _onThemeLoad(
    ThemeLoad event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      // Check if theme service is initialized
      final mode = _themeService.themeMode;
      emit(ThemeState(themeMode: mode));
    } catch (e) {
      // If there's an error, default to system theme
      emit(const ThemeState(themeMode: ThemeMode.system));
    }
  }

  Future<void> _onThemeChanged(
    ThemeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    final mode = event.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await _themeService.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> _onThemeToggled(
    ThemeToggled event,
    Emitter<ThemeState> emit,
  ) async {
    final newMode = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await _themeService.setThemeMode(newMode);
    emit(state.copyWith(themeMode: newMode));
  }
}
