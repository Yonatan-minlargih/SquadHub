import 'package:equatable/equatable.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ThemeChanged extends ThemeEvent {
  final bool isDarkMode;

  const ThemeChanged(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}

class ThemeToggled extends ThemeEvent {
  const ThemeToggled();
}

class ThemeLoad extends ThemeEvent {
  const ThemeLoad();
}

