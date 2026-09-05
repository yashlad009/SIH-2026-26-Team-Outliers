import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatters.dart';

class CaseVolumeChart extends StatelessWidget {
  /// List of (date, count) pairs for cases
  final List<MapEntry<DateTime, int>> data;
  /// Optional list of (date, count) pairs for referrals
  final List<MapEntry<DateTime, int>>? referralData;

  const CaseVolumeChart({
    super.key,
    required this.data,
    this.referralData,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();

    final refSpots = referralData != null && referralData!.isNotEmpty
        ? referralData!.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.value.toDouble());
          }).toList()
        : <FlSpot>[];

    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.divider, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  return Text(
                    DateFormatters.formatChartDate(data[idx].key),
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            if (refSpots.isNotEmpty)
              LineChartBarData(
                spots: refSpots,
                isCurved: true,
                color: AppColors.riskMedium,
                barWidth: 2.0,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.riskMedium.withValues(alpha: 0.05),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
