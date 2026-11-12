import 'package:flutter/material.dart';

/// Centralized color palette for DailySave.
/// Complies with Material 3 design and WCAG 2.1 AA accessibility guidelines
/// for contrast ratios (minimum 4.5:1 for normal text, 3:1 for large text/UI).
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primaryGreen = Color(0xFF16865B);
  static const Color primaryGreenLight = Color(0xFF1EA973);
  static const Color primaryGreenDark = Color(0xFF0F5A3D);

  static const Color darkNavy = Color(0xFF172554);
  static const Color darkNavyLight = Color(0xFF1E3A8A);
  static const Color darkNavySurface = Color(0xFF1E293B);

  // Background and Surface (Light Mode)
  static const Color backgroundLight = Color(0xFFF7F9F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightVariant = Color(0xFFF1F5F9);

  // Background and Surface (Dark Mode)
  static const Color backgroundDark = Color(0xFF0B1120);
  static const Color surfaceDark = Color(0xFF151F32);
  static const Color surfaceDarkVariant = Color(0xFF1E293B);

  // Functional & Semantic Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successBackground = Color(0xFFDCFCE7);

  static const Color expenseWarning = Color(0xFFDC2626);
  static const Color expenseWarningBackground = Color(0xFFFEE2E2);

  static const Color warningOrange = Color(0xFFD97706);
  static const Color infoBlue = Color(0xFF2563EB);

  // Neutral Greys & Text (Light Mode)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Neutral Greys & Text (Dark Mode)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF334155);

  // Focus & Accessibility
  static const Color focusRing = Color(0xFF2563EB);
  static const Color highContrastBorder = Color(0xFF0F172A);
}
