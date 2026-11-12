import 'package:flutter/material.dart';

/// Accessibility utilities to ensure DailySave complies with WCAG 2.1 AA
/// standards, including screen-reader semantics and touch targets.
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Minimum recommended interactive touch/click target size (48x48 dp).
  static const double minTouchTargetSize = 48.0;

  /// Formats currency numbers into natural words for screen-readers.
  /// Example: 125000 cents -> "1,250 Ethiopian Birr"
  static String formatCurrencyForScreenReader(int amountInCents) {
    final double amount = amountInCents / 100;
    final int whole = amount.truncate();
    final int cents = (amountInCents % 100).abs();

    if (cents == 0) {
      return '$whole Ethiopian Birr';
    } else {
      return '$whole Birr and $cents Cents';
    }
  }

  /// Wraps an interactive widget with minimum accessibility dimensions.
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
}
