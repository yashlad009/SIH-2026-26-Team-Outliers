import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../models/referral_model.dart';

class ReferralStatusStepper extends StatelessWidget {
  final ReferralStatus currentStatus;
  final bool compact;

  const ReferralStatusStepper({
    super.key,
    required this.currentStatus,
    this.compact = false,
  });

  static const _steps = [
    ReferralStatus.created,
    ReferralStatus.accepted,
    ReferralStatus.scheduled,
    ReferralStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final isDropped = currentStatus == ReferralStatus.dropped;

    if (isDropped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.statusDropped, size: 18),
            const SizedBox(width: 6),
            Text(
              'Referral Dropped',
              style: TextStyle(
                color: AppColors.statusDropped,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return compact ? _buildCompact() : _buildFull(context);
  }

  Widget _buildCompact() {
    final currentIdx = _steps.indexOf(currentStatus);
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIdx = i ~/ 2;
          final isActive = stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: isActive ? AppColors.primary : AppColors.divider,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isDone = stepIdx < currentIdx;
        final isCurrent = stepIdx == currentIdx;
        return _StepDot(
          isDone: isDone,
          isCurrent: isCurrent,
          label: _steps[stepIdx].label,
          compact: true,
        );
      }),
    );
  }

  Widget _buildFull(BuildContext context) {
    final currentIdx = _steps.indexOf(currentStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isDone = i < currentIdx;
        final isCurrent = i == currentIdx;
        return _FullStepRow(
          step: step,
          isDone: isDone,
          isCurrent: isCurrent,
          isLast: i == _steps.length - 1,
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;
  final String label;
  final bool compact;

  const _StepDot({
    required this.isDone,
    required this.isCurrent,
    required this.label,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.primary
        : isCurrent
            ? AppColors.primaryLight
            : AppColors.divider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 10, color: Colors.white)
              : null,
        ),
      ],
    );
  }
}

class _FullStepRow extends StatelessWidget {
  final ReferralStatus step;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _FullStepRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.primary
        : isCurrent
            ? AppColors.primaryLight
            : AppColors.textHint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary
                      : isCurrent
                          ? AppColors.primaryContainer
                          : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? AppColors.primary : AppColors.divider,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : isCurrent
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppColors.primary : AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? AppColors.primary : color,
                    fontSize: 14,
                  ),
                ),
                if (isCurrent)
                  Text(
                    'Current Status',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryLight,
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
