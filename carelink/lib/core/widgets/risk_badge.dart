import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../models/triage_result_model.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;
  final bool showScore;
  final int? score;
  final bool large;

  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.showScore = false,
    this.score,
    this.large = false,
  });

  Color get _bg {
    switch (riskLevel) {
      case RiskLevel.high:
        return AppColors.riskHighLight;
      case RiskLevel.medium:
        return AppColors.riskMediumLight;
      case RiskLevel.low:
        return AppColors.riskLowLight;
    }
  }

  Color get _fg {
    switch (riskLevel) {
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.low:
        return AppColors.riskLow;
    }
  }

  IconData get _icon {
    switch (riskLevel) {
      case RiskLevel.high:
        return Icons.warning_rounded;
      case RiskLevel.medium:
        return Icons.info_rounded;
      case RiskLevel.low:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = riskLevel.label;
    final scoreText = showScore && score != null ? '  ·  $score/100' : '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(large ? 12 : 20),
        border: Border.all(color: _fg.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: large ? 20 : 14, color: _fg),
          const SizedBox(width: 6),
          Text(
            '$label$scoreText',
            style: TextStyle(
              color: _fg,
              fontSize: large ? 15 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
