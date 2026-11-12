import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Comprehensive Accessibility Utilities ensuring DailySave complies with WCAG 2.2 AA standards.
///
/// Principles enforced:
/// - 1. Perceivable: Screen-reader announcements, high contrast (>4.5:1), natural speech currency.
/// - 2. Operable: Minimum 48x48 dp touch targets, keyboard focus indicators, no gesture-only traps.
/// - 3. Understandable: Predictable structure, explicit labels, human-friendly error messages.
/// - 4. Robust: Clean semantics trees without audio-only dependencies.
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Minimum recommended interactive touch/click target size under WCAG 2.2 (48x48 dp).
  static const double minTouchTargetSize = 48.0;

  /// Announces a message aloud to screen-readers (TalkBack / VoiceOver / JAWS / NVDA).
  static void announce(String message, {TextDirection textDirection = TextDirection.ltr}) {
    SemanticsService.announce(message, textDirection);
  }

  /// Converts integer minor currency units into human-sounding speech for screen-readers.
  /// Example: 150000 cents -> "1,500 Ethiopian Birr"
  /// Example: -20000 cents -> "Negative 200 Ethiopian Birr"
  static String formatCurrencyForScreenReader(int amountInCents) {
    final bool isNegative = amountInCents < 0;
    final int absCents = amountInCents.abs();
    final int whole = absCents ~/ 100;
    final int remainderCents = absCents % 100;

    final String prefix = isNegative ? 'Negative ' : '';

    if (remainderCents == 0) {
      return '$prefix$whole Ethiopian Birr';
    } else {
      return '$prefix$whole Birr and $remainderCents Cents';
    }
  }

  /// Calculates relative luminance of an sRGB color.
  static double calculateLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Computes the WCAG contrast ratio between two colors (ranges from 1.0 to 21.0).
  /// WCAG 2.2 AA requires:
  /// - At least 4.5:1 for normal body text.
  /// - At least 3.0:1 for large text (>= 18pt or bold >= 14pt) and essential UI icons.
  static double calculateContrastRatio(Color foreground, Color background) {
    final double l1 = calculateLuminance(foreground);
    final double l2 = calculateLuminance(background);
    final double lighter = l1 > l2 ? l1 : l2;
    final double darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Validates whether a foreground and background color combination passes WCAG 2.2 AA.
  static bool passesWcagAA(Color foreground, Color background, {bool isLargeText = false}) {
    final double ratio = calculateContrastRatio(foreground, background);
    return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// Wraps an interactive widget to guarantee minimum 48x48 dp touch target dimensions.
  static Widget ensureMinTouchTarget({
    required Widget child,
    double minWidth = minTouchTargetSize,
    double minHeight = minTouchTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: Center(
        child: child,
      ),
    );
  }

  /// Builds an accessible card with explicit semantic container and screen-reader summary.
  static Widget semanticFinancialCard({
    required Widget child,
    required String semanticLabel,
    String? hint,
  }) {
    return Semantics(
      container: true,
      label: semanticLabel,
      hint: hint,
      excludeSemantics: true,
      child: child,
    );
  }
}
