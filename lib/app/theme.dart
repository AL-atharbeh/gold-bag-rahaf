import 'package:flutter/material.dart';

/// لوحة ألوان الهوية البصرية الفاخرة (White & Gold Theme)
class AppColors {
  // تدرجات الذهب الملكي
  static const Color goldPrimary = Color(0xFFC5A059);
  static const Color goldDark = Color(0xFF9E7B32);
  static const Color goldLight = Color(0xFFDFBA68);
  static const Color goldShimmer = Color(0xFFF5E8C7);
  static const Color goldContainer = Color(0xFFFBF8F1);
  static const Color goldBorder = Color(0xFFEADCB8);

  // الخلفيات والأسطح
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFBFBF9);
  static const Color surfaceMuted = Color(0xFFF5F3ED);

  // النصوص والتباين
  static const Color textPrimary = Color(0xFF1E1B18);
  static const Color textSecondary = Color(0xFF6B655D);
  static const Color textMuted = Color(0xFF9E978E);

  // الحدود والفواصل
  static const Color border = Color(0xFFECE7DC);
  static const Color borderSubtle = Color(0xFFF3EFE6);

  // الحالات
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFEBF7ED);
  static const Color error = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFDECEC);
  static const Color info = Color(0xFF1976D2);
  static const Color infoContainer = Color(0xFFEAF2FD);

  // تدرج ذهبي فاخر للعناصر البارزة
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFDFBA68), Color(0xFFB58E38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldCardGradient = LinearGradient(
    colors: [Color(0xFFFFFDF9), Color(0xFFF8F3E6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// بناء الثيم الموحّد للأجهزة اللوحية والمحمولة
ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // حتى في الوضع الداكن يتم الحفاظ على لمسات الذهب، لكن التركيز الأساسي على الأبيض والذهبي الفاخر
  final primaryColor = AppColors.goldPrimary;
  final scheme = isDark
      ? ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: AppColors.goldLight,
          onPrimary: const Color(0xFF141210),
          surface: const Color(0xFF181614),
          onSurface: const Color(0xFFEDE8DF),
          outline: const Color(0xFF3D372E),
          outlineVariant: const Color(0xFF2C2720),
          surfaceContainerHighest: const Color(0xFF24201B),
        )
      : const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.goldPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.goldContainer,
          onPrimaryContainer: AppColors.goldDark,
          secondary: AppColors.goldDark,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.goldContainer,
          onSecondaryContainer: AppColors.goldDark,
          tertiary: Color(0xFF8C6D23),
          onTertiary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.surfaceMuted,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: AppColors.borderSubtle,
        );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF141210) : AppColors.background,
    visualDensity: VisualDensity.comfortable,

    // شريط التطبيق العلوي
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF181614) : AppColors.surface,
      foregroundColor: isDark ? AppColors.goldLight : AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.goldLight : AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(
        color: isDark ? AppColors.goldLight : AppColors.goldDark,
      ),
    ),

    // البطاقات
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1B17) : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF383126) : AppColors.border,
          width: 1,
        ),
      ),
    ),

    // الأزرار المعبأة (Filled Buttons)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),

    // الأزرار المحددة (Outlined Buttons)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.goldDark,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: AppColors.goldBorder, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // الأزرار النصية (Text Buttons)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.goldDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // حقول الإدخال (Inputs)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1B17) : AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFFA8A095) : AppColors.textSecondary,
        fontSize: 15,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF383126) : AppColors.border,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF383126) : AppColors.border,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.goldPrimary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      prefixIconColor: AppColors.goldDark,
      suffixIconColor: AppColors.textSecondary,
    ),

    // شريط التجزئة والتبديل (Segmented Button)
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor:
            isDark ? const Color(0xFF3D321D) : AppColors.goldContainer,
        selectedForegroundColor:
            isDark ? AppColors.goldLight : AppColors.goldDark,
        foregroundColor:
            isDark ? const Color(0xFFC0B8AD) : AppColors.textSecondary,
        backgroundColor:
            isDark ? const Color(0xFF1A1815) : AppColors.surfaceLight,
        side: BorderSide(
          color: isDark ? const Color(0xFF3D372E) : AppColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // شريط التنقل السفلي (Bottom Navigation Bar)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF181614) : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: Colors.black12,
      indicatorColor:
          isDark ? const Color(0xFF3D321D) : AppColors.goldContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.goldDark, size: 24);
        }
        return IconThemeData(
          color: isDark ? const Color(0xFF8E867C) : AppColors.textMuted,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.goldDark,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF8E867C) : AppColors.textMuted,
        );
      }),
    ),

    // شريط التنقل الجانبي للتابلت (Navigation Rail)
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isDark ? const Color(0xFF181614) : AppColors.surface,
      indicatorColor:
          isDark ? const Color(0xFF3D321D) : AppColors.goldContainer,
      selectedIconTheme:
          const IconThemeData(color: AppColors.goldDark, size: 26),
      unselectedIconTheme: IconThemeData(
        color: isDark ? const Color(0xFF8E867C) : AppColors.textMuted,
        size: 24,
      ),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.goldDark,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFF8E867C) : AppColors.textMuted,
      ),
    ),

    // النوافذ المنبثقة (Dialogs)
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? const Color(0xFF1E1B17) : AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF383126) : AppColors.border,
          width: 1,
        ),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.goldLight : AppColors.textPrimary,
      ),
    ),

    // الفواصل (Dividers)
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF2C2720) : AppColors.borderSubtle,
      thickness: 1,
      space: 1,
    ),

    // زر الإجراء العائم (Floating Action Button)
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.goldPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      focusElevation: 4,
      hoverElevation: 6,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // رسائل التنبيه (SnackBars)
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF2C2822) : AppColors.textPrimary,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
