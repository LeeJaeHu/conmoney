import 'package:flutter/material.dart';

/// 앱 디자인(10/16 결정: B2 "깔끔한 금융앱 + 예산 게이지").
/// 회색 바탕 위 흰 카드, 파랑 하나만 강조색. 초과·평소보다 많음은 빨강 대신 주황.
/// 색은 모두 여기서 정하고 화면 코드는 Theme에서 읽는다.
class AppColors {
  static const blue = Color(0xFF185FA5);
  static const blueLight = Color(0xFF378ADD);
  static const blueDark = Color(0xFF85B7EB);
  static const ink = Color(0xFF042C53);

  static const bgLight = Color(0xFFF2F3F5);
  static const bgDark = Color(0xFF111316);
  static const cardDark = Color(0xFF1C1F24);

  /// 초과·많이 씀(빨강 대신, 스트레스 최소화 원칙)
  static Color warm(Brightness b) => b == Brightness.dark ? const Color(0xFFFFB46B) : const Color(0xFFC25E00);

  /// 게이지 바탕
  static Color track(Brightness b) => b == Brightness.dark ? const Color(0xFF26313D) : const Color(0xFFE6F1FB);
}

/// 앱 글꼴(Pretendard, `assets/fonts`, SIL OFL 1.1).
const appFont = 'Pretendard';

/// 금액처럼 자릿수가 세로로 맞아야 하는 숫자.
const tabular = [FontFeature.tabularFigures()];

/// [fontFamily]: 글꼴을 묶어 넣으면 여기로 지정한다(없으면 기기 기본 글꼴). 화면 캡처 테스트는 맑은 고딕을 넣는다.
ThemeData buildTheme(Brightness brightness, {String? fontFamily}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.blue, brightness: brightness).copyWith(
    primary: dark ? AppColors.blueDark : AppColors.blue,
    onPrimary: dark ? AppColors.ink : Colors.white,
    surface: dark ? AppColors.cardDark : Colors.white,
    surfaceContainerLowest: dark ? AppColors.bgDark : AppColors.bgLight,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: brightness, fontFamily: fontFamily);
  final bg = dark ? AppColors.bgDark : AppColors.bgLight;
  final text = base.textTheme;
  const radius = 16.0;

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1, fontFeatures: tabular),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5, fontFeatures: tabular),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    // 최소 너비를 무한(Size.fromHeight)으로 두면 ListTile trailing·Row·Wrap 안의 버튼이 레이아웃을 깨뜨려
    // 화면이 통째로 빈다(10/17 예정 지출·먼저 알려주기·정기 지출). 꽉 찬 너비는 ListView·SizedBox가 정한다.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: scheme.surface,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      backgroundColor: scheme.surface,
      selectedColor: dark ? const Color(0xFF26313D) : const Color(0xFFE6F1FB),
    ),
    listTileTheme: const ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius)))),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5), space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}
