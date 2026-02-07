import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS 18 Design System for Delivery Driver App
class IOSTheme {
  // Colors - iOS System Colors
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosBlueDark = Color(0xFF0051D5);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosRed = Color(0xFFFF3B30);
  static const Color iosOrange = Color(0xFFFF9500);
  static const Color iosYellow = Color(0xFFFFCC00);
  static const Color iosPurple = Color(0xFFAF52DE);
  static const Color iosPink = Color(0xFFFF2D55);
  static const Color iosTeal = Color(0xFF5AC8FA);
  static const Color iosIndigo = Color(0xFF5856D6);

  // Background Colors
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF2F2F7);
  static const Color bgTertiary = Color(0xFFFFFFFF);
  static const Color bgGrouped = Color(0xFFF2F2F7);

  // Text Colors
  static const Color label = Color(0xFF000000);
  static const Color labelSecondary = Color(0x993C3C43);
  static const Color labelTertiary = Color(0x4D3C3C43);

  // UI Colors
  static const Color separator = Color(0x4A3C3C43);
  static const Color fill = Color(0x33787880);

  // Border Radius
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2Xl = 24;
  static const double radiusFull = 9999;

  // Shadows
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Typography
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  // Haptic Feedback
  static void lightImpact() => HapticFeedback.lightImpact();
  static void mediumImpact() => HapticFeedback.mediumImpact();
  static void heavyImpact() => HapticFeedback.heavyImpact();

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgSecondary,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSecondary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: headline,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        color: bgPrimary,
      ),
    );
  }
}

/// iOS Card Widget
class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const IOSCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
        boxShadow: IOSTheme.shadowSm,
      ),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: () {
          IOSTheme.lightImpact();
          onTap!();
        },
        child: card,
      );
    }

    return card;
  }
}

/// Status Badge
class StatusBadge extends StatelessWidget {
  final String text;
  final StatusBadgeType type;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = StatusBadgeType.info,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (type) {
      case StatusBadgeType.success:
        bgColor = IOSTheme.iosGreen.withOpacity(0.15);
        textColor = IOSTheme.iosGreen;
        break;
      case StatusBadgeType.warning:
        bgColor = IOSTheme.iosOrange.withOpacity(0.15);
        textColor = IOSTheme.iosOrange;
        break;
      case StatusBadgeType.error:
        bgColor = IOSTheme.iosRed.withOpacity(0.15);
        textColor = IOSTheme.iosRed;
        break;
      case StatusBadgeType.info:
        bgColor = IOSTheme.iosBlue.withOpacity(0.15);
        textColor = IOSTheme.iosBlue;
        break;
      case StatusBadgeType.pending:
        bgColor = IOSTheme.fill;
        textColor = IOSTheme.labelSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(IOSTheme.radiusFull),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum StatusBadgeType {
  success,
  warning,
  error,
  info,
  pending,
}
