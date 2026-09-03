import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TriageDistributionChart extends StatefulWidget {
  final int high;
  final int medium;
  final int low;

  const TriageDistributionChart({
    super.key,
    required this.high,
    required this.medium,
    required this.low,
  });

  @override
  State<TriageDistributionChart> createState() =>
      _TriageDistributionChartState();
}

class _TriageDistributionChartState extends State<TriageDistributionChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.high + widget.medium + widget.low;
    if (total == 0) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: [
                  _section(widget.high, AppColors.riskHigh, 'High', 0),
                  _section(widget.medium, AppColors.riskMedium, 'Med', 1),
                  _section(widget.low, AppColors.riskLow, 'Low', 2),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legend(AppColors.riskHigh, 'High Risk', widget.high, total),
            const SizedBox(height: 8),
            _legend(AppColors.riskMedium, 'Medium Risk', widget.medium, total),
            const SizedBox(height: 8),
            _legend(AppColors.riskLow, 'Low Risk', widget.low, total),
          ],
        ),
      ],
    );
  }

  PieChartSectionData _section(
      int value, Color color, String title, int index) {
    final isTouched = index == _touchedIndex;
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      title: '$value',
      radius: isTouched ? 50 : 44,
      titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white),
    );
  }

  Widget _legend(Color color, String label, int count, int total) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count ($pct%)',
            style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
