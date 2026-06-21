import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════
// CS2 RCON 控制面板 — 设计令牌
//   基准间距: 4 px  (4, 8, 12, 16, 20, 24, 32, 40, …)
//   色板:     Slate 灰色系 (背景/表面) + Emerald 绿色 (强调色)
//   字体:     Noto Sans SC (界面) + JetBrains Mono (代码)
// ═══════════════════════════════════════════════════════

// ── 颜色 ──────────────────────────────────────────────
class CS2Colors {
  CS2Colors._();

  // Slate 灰色系 — 背景、表面、文字
  static const slate50  = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate750 = Color(0xFF2D3748);
  static const slate800 = Color(0xFF1E293B);
  static const slate850 = Color(0xFF172033);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);

  // Emerald — 强调色 / 正向操作
  static const emerald50  = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);

  // 危险/错误
  static const red400  = Color(0xFFF87171);
  static const red500  = Color(0xFFEF4444);
  static const red600  = Color(0xFFDC2626);
  static const red700  = Color(0xFFB91C1C);
  static const red900  = Color(0xFF7F1D1D);

  // 警告 / 信息
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const blue400  = Color(0xFF60A5FA);
  static const blue500  = Color(0xFF3B82F6);

  // 语义别名
  static const surface = slate950;
  static const surfaceAlt = slate900;
  static const card = slate850;
  static const cardBorder = slate800;
  static const inputFill = slate900;
  static const inputBorder = slate700;
  static const textPrimary = slate100;
  static const textSecondary = slate400;
  static const textMuted = slate600;
  static const accent = emerald500;
  static const accentHover = emerald400;
  static const destructive = red500;
  static const destructiveHover = red400;
  static const warning = amber500;
  static const info = blue400;
  static const success = emerald500;
  static const statusOnline = emerald500;
  static const statusOffline = slate600;
  static const statusConnecting = amber400;
}

// ── 间距 (4 px 基准) ──────────────────────────────────
class CS2Spacing {
  CS2Spacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
}

// ── 圆角 ──────────────────────────────────────────────
class CS2Radius {
  CS2Radius._();
  static const double sm  = 4;
  static const double md  = 8;
  static const double lg  = 12;
  static const double xl  = 16;
}

// ── 字体设置 ──────────────────────────────────────────
// UI 界面字体: Noto Sans SC (支持中文)
// 代码/日志字体: JetBrains Mono (等宽)
class CS2Fonts {
  CS2Fonts._();

  /// 获取 UI 界面文字样式 (Noto Sans SC)
  static TextStyle ui({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = CS2Colors.textPrimary,
    double? letterSpacing,
  }) =>
      GoogleFonts.notoSansSc(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// 获取等宽/代码文字样式 (JetBrains Mono)
  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color color = CS2Colors.textPrimary,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );
}

// ── 文字样式 ──────────────────────────────────────────
class CS2TextStyles {
  CS2TextStyles._();

  // UI 文字 (Noto Sans SC) ————

  static TextStyle get headline =>
      CS2Fonts.ui(size: 22, weight: FontWeight.w700, letterSpacing: -0.5);

  static TextStyle get title =>
      CS2Fonts.ui(size: 17, weight: FontWeight.w600);

  static TextStyle get subtitle =>
      CS2Fonts.ui(size: 14, weight: FontWeight.w500, color: CS2Colors.textSecondary);

  static TextStyle get body =>
      CS2Fonts.ui(size: 13, weight: FontWeight.w400);

  static TextStyle get bodySmall =>
      CS2Fonts.ui(size: 12, weight: FontWeight.w400, color: CS2Colors.textSecondary);

  static TextStyle get label =>
      CS2Fonts.ui(size: 11, weight: FontWeight.w600, letterSpacing: 0.5);

  static TextStyle get buttonText =>
      CS2Fonts.ui(size: 13, weight: FontWeight.w600, letterSpacing: 0.3);

  // 等宽文字 (JetBrains Mono) ————

  static TextStyle get code =>
      CS2Fonts.mono(size: 12, weight: FontWeight.w400);

  static TextStyle get logTimestamp =>
      CS2Fonts.mono(size: 11, weight: FontWeight.w400, color: CS2Colors.textMuted);

  static TextStyle get logCommand =>
      CS2Fonts.mono(size: 12, weight: FontWeight.w600, color: CS2Colors.emerald400);

  static TextStyle get logResponse =>
      CS2Fonts.mono(size: 12, weight: FontWeight.w400, color: CS2Colors.slate200);

  static TextStyle get logError =>
      CS2Fonts.mono(size: 12, weight: FontWeight.w400, color: CS2Colors.red400);
}

// ── 主题 ──────────────────────────────────────────────
class CS2Theme {
  CS2Theme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: CS2Colors.surface,
        colorScheme: const ColorScheme.dark(
          primary: CS2Colors.emerald500,
          onPrimary: Colors.black,
          secondary: CS2Colors.slate600,
          onSecondary: CS2Colors.slate100,
          surface: CS2Colors.slate950,
          onSurface: CS2Colors.slate100,
          error: CS2Colors.red500,
          onError: Colors.white,
        ),

        // 全局文字主题 — 使用 Noto Sans SC
        textTheme: GoogleFonts.notoSansScTextTheme(ThemeData.dark().textTheme),

        appBarTheme: AppBarTheme(
          backgroundColor: CS2Colors.surfaceAlt,
          foregroundColor: CS2Colors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
          titleTextStyle: CS2TextStyles.title,
        ),
        cardTheme: CardThemeData(
          color: CS2Colors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CS2Radius.md),
            side: const BorderSide(color: CS2Colors.cardBorder, width: 1),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: CS2Spacing.lg,
            vertical: CS2Spacing.sm,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CS2Colors.inputFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CS2Spacing.lg,
            vertical: CS2Spacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CS2Radius.md),
            borderSide: const BorderSide(color: CS2Colors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CS2Radius.md),
            borderSide: const BorderSide(color: CS2Colors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CS2Radius.md),
            borderSide: const BorderSide(color: CS2Colors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CS2Radius.md),
            borderSide: const BorderSide(color: CS2Colors.destructive),
          ),
          labelStyle: CS2TextStyles.bodySmall,
          hintStyle: CS2TextStyles.bodySmall,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: CS2Colors.accent,
            foregroundColor: Colors.black,
            disabledBackgroundColor: CS2Colors.slate700,
            disabledForegroundColor: CS2Colors.slate500,
            padding: const EdgeInsets.symmetric(
              horizontal: CS2Spacing.xl,
              vertical: CS2Spacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CS2Radius.md),
            ),
            textStyle: CS2TextStyles.buttonText,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: CS2Colors.textPrimary,
            side: const BorderSide(color: CS2Colors.slate600),
            padding: const EdgeInsets.symmetric(
              horizontal: CS2Spacing.lg,
              vertical: CS2Spacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CS2Radius.md),
            ),
            textStyle: CS2TextStyles.buttonText,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: CS2Colors.accent,
            textStyle: CS2TextStyles.buttonText,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: CS2Colors.slate800,
          contentTextStyle: CS2TextStyles.body,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CS2Radius.md),
            side: const BorderSide(color: CS2Colors.slate700),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dividerTheme: const DividerThemeData(
          color: CS2Colors.cardBorder,
          thickness: 1,
          space: 1,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: CS2Colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CS2Radius.lg),
            side: const BorderSide(color: CS2Colors.cardBorder),
          ),
          titleTextStyle: CS2TextStyles.title,
          contentTextStyle: CS2TextStyles.body,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: CS2Colors.surfaceAlt,
          selectedItemColor: CS2Colors.accent,
          unselectedItemColor: CS2Colors.textMuted,
          type: BottomNavigationBarType.fixed,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: CS2Colors.accent,
          unselectedLabelColor: CS2Colors.textSecondary,
          indicatorColor: CS2Colors.accent,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(CS2Colors.slate600),
          trackColor: WidgetStateProperty.all(CS2Colors.slate800),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: CS2Colors.accent,
        ),
      );
}

// ── BuildContext 扩展 ─────────────────────────────────
extension CS2Context on BuildContext {
  ThemeData get cs2Theme => Theme.of(this);
  ColorScheme get cs2Colors => Theme.of(this).colorScheme;
  TextTheme get cs2Text => Theme.of(this).textTheme;
}
