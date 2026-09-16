import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide dark/light mode switch. Visual-only, no effect on API/business logic.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  bool _isDark = true;
  bool get isDark => _isDark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDark);
  }
}

/// Makes [ThemeController] available to the whole widget tree and rebuilds
/// every widget that reads [AppTheme.isDark] when the mode changes -
/// including screens already pushed on the Navigator stack.
class AppTheme extends InheritedNotifier<ThemeController> {
  const AppTheme({super.key, required ThemeController controller, required super.child})
      : super(notifier: controller);

  static ThemeController _of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(widget != null, 'AppTheme.of() called with no AppTheme ancestor.');
    return widget!.notifier!;
  }

  static bool isDark(BuildContext context) => _of(context).isDark;

  static void toggle(BuildContext context) => _of(context).toggle();
}
