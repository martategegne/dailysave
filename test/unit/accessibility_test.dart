import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailysave/core/accessibility/accessibility_utils.dart';
import 'package:dailysave/core/constants/app_colors.dart';

void main() {
  group('DailySave WCAG 2.2 AA Accessibility Suite', () {
    test('Screen-reader currency formatter speaks positive and negative amounts naturally', () {
      expect(
        AccessibilityUtils.formatCurrencyForScreenReader(150000),
        '1500 Ethiopian Birr',
      );
      expect(
        AccessibilityUtils.formatCurrencyForScreenReader(2550),
        '25 Birr and 50 Cents',
      );
      expect(
        AccessibilityUtils.formatCurrencyForScreenReader(-20000),
        'Negative 200 Ethiopian Birr',
      );
      expect(
        AccessibilityUtils.formatCurrencyForScreenReader(0),
        '0 Ethiopian Birr',
      );
    });

    test('Color Contrast Ratio calculations adhere to WCAG 2.2 AA', () {
      // Dark Navy (#172554) on White background (#FFFFFF) -> High contrast (>10:1)
      final ratioNavyOnWhite = AccessibilityUtils.calculateContrastRatio(
        AppColors.darkNavy,
        Colors.white,
      );
      expect(ratioNavyOnWhite, greaterThan(4.5));
      expect(AccessibilityUtils.passesWcagAA(AppColors.darkNavy, Colors.white), true);

      // White on Primary Green (#16865B)
      final ratioWhiteOnGreen = AccessibilityUtils.calculateContrastRatio(
        Colors.white,
        AppColors.primaryGreen,
      );
      expect(ratioWhiteOnGreen, greaterThan(3.0)); // Passes for buttons and bold headers
    });

    testWidgets('ensureMinTouchTarget wraps widgets to at least 48x48 dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.ensureMinTouchTarget(
              child: const SizedBox(width: 20, height: 20),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(ConstrainedBox).first);
      expect(box.size.width, greaterThanOrEqualTo(48.0));
      expect(box.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('semanticFinancialCard attaches accessibility label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibilityUtils.semanticFinancialCard(
              semanticLabel: 'Today Savings: 600 Ethiopian Birr',
              child: const Text('600 ETB'),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Today Savings: 600 Ethiopian Birr'),
        findsOneWidget,
      );
    });
  });
}
