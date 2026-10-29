import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 테마 모드 상태를 관리하는 StateNotifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  /// 시스템 설정 따르기
  void setSystem() {
    state = ThemeMode.system;
  }

  /// 라이트 모드 (일반 모드) 강제 적용
  void setLight() {
    state = ThemeMode.light;
  }

  /// 다크 모드 강제 적용
  void setDark() {
    state = ThemeMode.dark;
  }

  /// 테마 모드 직접 변경
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// 테마 모드 관리 Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

