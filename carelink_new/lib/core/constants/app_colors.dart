import 'package:flutter/material.dart';

/// CareLink Color System
/// - Primary palette: teal/blue → clinical trust
/// - Risk colors: red/amber/green → ONLY for triage risk levels
/// - Never use risk colors for non-triage UI
class AppColors {
  AppColors._();

  // ── Primary (clinical trust) ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0077B6); // deep teal-blue
  static const Color primaryLight = Color(0xFF00B4D8);
  static const Color primaryDark = Color(0xFF023E8A);
  static const Color primaryContainer = Color(0xFFCAF0F8);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF0096C7);
  static const Color secondaryContainer = Color(0xFFADE8F4);

  // ── Surface / Background ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF0F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8F4FD);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Risk Levels (TRIAGE ONLY — do not repurpose) ──────────────────────────
  static const Color riskHigh = Color(0xFFD32F2F);
  static const Color riskHighLight = Color(0xFFFFCDD2);
  static const Color riskMedium = Color(0xFFF57C00);
  static const Color riskMediumLight = Color(0xFFFFE0B2);
  static const Color riskLow = Color(0xFF388E3C);
  static const Color riskLowLight = Color(0xFFC8E6C9);

  // ── Status colors (neutral — for referral/consult status) ─────────────────
  static const Color statusCreated = Color(0xFF0288D1);
  static const Color statusAccepted = Color(0xFF7B1FA2);
  static const Color statusScheduled = Color(0xFF1565C0);
  static const Color statusCompleted = Color(0xFF2E7D32);
  static const Color statusDropped = Color(0xFF757575);

  // ── Connectivity ──────────────────────────────────────────────────────────
  static const Color offlineBanner = Color(0xFF455A64);
  static const Color onlineBanner = Color(0xFF1B5E20);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF4A6274);
  static const Color textHint = Color(0xFF9AABB8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Divider / Border ──────────────────────────────────────────────────────
  static const Color divider = Color(0xFFDDE8EF);
  static const Color border = Color(0xFFB8D4E3);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const Color iconDefault = Color(0xFF4A6274);
  static const Color shadow = Color(0x1A0077B6);
}
