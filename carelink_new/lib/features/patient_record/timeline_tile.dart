import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatters.dart';

class TimelineTile extends StatelessWidget {
  final String event; // 'triage' | 'consult' | 'referral' | 'diagnostic'
  final DateTime timestamp;
  final bool isLast;
  final Widget child;

  const TimelineTile({
    super.key,
    required this.event,
    required this.timestamp,
    required this.isLast,
    required this.child,
  });

  Color get _dotColor {
    switch (event) {
      case 'triage':
        return AppColors.riskMedium;
      case 'consult':
        return AppColors.secondary;
      case 'referral':
        return AppColors.statusCreated;
      case 'diagnostic':
        return AppColors.statusScheduled;
      default:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (event) {
      case 'triage':
        return Icons.monitor_heart_outlined;
      case 'consult':
        return Icons.video_call_outlined;
      case 'referral':
        return Icons.local_hospital_outlined;
      case 'diagnostic':
        return Icons.biotech_outlined;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _dotColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: _dotColor, width: 1.5),
                ),
                child: Icon(_icon, size: 18, color: _dotColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatters.formatRelative(timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
