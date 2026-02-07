import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS 18 Design System for Flutter
/// Glassmorphism, spring animations, Manrope font
class IOSTheme {
  // Colors
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemBlueDark = Color(0xFF0051D5);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemIndigo = Color(0xFF5856D6);

  // Backgrounds
  static const Color bgPrimary = Color(0xFFF2F2F7);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgTertiary = Color(0xFFF2F2F7);
  
  // Labels
  static const Color labelPrimary = Color(0xFF000000);
  static const Color labelSecondary = Color(0x993C3C43); // 60% opacity
  static const Color labelTertiary = Color(0x4D3C3C43);  // 30% opacity
  static const Color labelQuaternary = Color(0x2E3C3C43); // 18% opacity

  // Separators
  static const Color separator = Color(0x4A3C3C43);
  static const Color fill = Color(0x33787880);

  // Glass Effect
  static const Color glassBackground = Color(0xB8FFFFFF);
  static const Color glassBorder = Color(0x3DFFFFFF);

  // Border Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2Xl = 24;

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

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

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // Typography
  static const TextStyle title1 = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: labelPrimary,
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: labelPrimary,
  );

  static const TextStyle title3 = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: labelPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: labelPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: labelPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: labelPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: labelSecondary,
  );

  static const TextStyle footnote = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: labelSecondary,
  );

  // Haptic Feedback
  static void lightImpact() => HapticFeedback.lightImpact();
  static void mediumImpact() => HapticFeedback.mediumImpact();
  static void heavyImpact() => HapticFeedback.heavyImpact();
  static void success() => HapticFeedback.heavyImpact();
  static void error() => HapticFeedback.vibrate();
  static void selection() => HapticFeedback.selectionClick();
}

/// Glassmorphism Container
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? IOSTheme.glassBackground,
        borderRadius: BorderRadius.circular(borderRadius ?? IOSTheme.radiusXl),
        border: Border.all(
          color: IOSTheme.glassBorder,
          width: 1,
        ),
        boxShadow: boxShadow ?? IOSTheme.shadowMd,
      ),
      child: child,
    );
  }
}

/// iOS Button
class IOSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final IconData? icon;
  final bool isLoading;

  const IOSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDestructive
        ? IOSTheme.systemRed
        : isPrimary
            ? IOSTheme.systemBlue
            : IOSTheme.fill;
    
    final textColor = isPrimary || isDestructive
        ? Colors.white
        : IOSTheme.systemBlue;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: onPressed == null ? IOSTheme.fill : bgColor,
          borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
          boxShadow: isPrimary ? IOSTheme.shadowSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(textColor),
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: IOSTheme.headline.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// iOS Card
class IOSCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const IOSCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(IOSTheme.spacingMd),
      decoration: BoxDecoration(
        color: backgroundColor ?? IOSTheme.bgSecondary,
        borderRadius: BorderRadius.circular(IOSTheme.radiusXl),
        boxShadow: IOSTheme.shadowSm,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
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
