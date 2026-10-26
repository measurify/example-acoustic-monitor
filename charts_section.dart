import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'info_card.dart';

class ChartsSection extends StatelessWidget {
  final List<FlSpot> dbaHistory;
  final List<double> fftBands;
  final List<FlSpot> accXHistory;
  final List<FlSpot> accYHistory;
  final List<FlSpot> accZHistory;

  const ChartsSection({
    super.key,
    required this.dbaHistory,
    required this.fftBands,
    required this.accXHistory,
    required this.accYHistory,
    required this.accZHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InfoCard(
          title: 'LIVELLO SONORO LIVE',
          icon: Icons.multiline_chart_rounded,
          trailing: _LegendChip(label: 'dB(A)', color: AppTheme.green),
          highlightColor: AppTheme.green,
          child: SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.stroke.withOpacity(0.45),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: dbaHistory.isEmpty ? const [FlSpot(0, 0)] : dbaHistory,
                    isCurved: true,
                    color: AppTheme.green,
                    barWidth: 3.2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.green.withOpacity(0.24),
                          AppTheme.green.withOpacity(0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: 'SPETTRO FFT',
          icon: Icons.graphic_eq_rounded,
          trailing: const _LegendChip(label: '16 bande', color: AppTheme.cyan),
          highlightColor: AppTheme.cyan,
          child: SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.stroke.withOpacity(0.45),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
                barGroups: (fftBands.isEmpty ? List.filled(16, 0.0) : fftBands)
                    .asMap()
                    .entries
                    .map((entry) {
                  final value = entry.value;
                  final color = Color.lerp(AppTheme.cyan, AppTheme.blue, entry.key / 16)!;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 10,
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.75), color],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InfoCard(
          title: 'VIBRAZIONI X / Y / Z',
          icon: Icons.vibration_rounded,
          trailing: const Wrap(
            spacing: 8,
            children: [
              _LegendChip(label: 'X', color: AppTheme.red),
              _LegendChip(label: 'Y', color: AppTheme.green),
              _LegendChip(label: 'Z', color: AppTheme.blue),
            ],
          ),
          highlightColor: AppTheme.blue,
          child: SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.stroke.withOpacity(0.45),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: true),
                lineBarsData: [
                  _buildLine(accXHistory, AppTheme.red),
                  _buildLine(accYHistory, AppTheme.green),
                  _buildLine(accZHistory, AppTheme.blue),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLine(List<FlSpot> points, Color color) {
    return LineChartBarData(
      spots: points.isEmpty ? const [FlSpot(0, 0)] : points,
      isCurved: true,
      color: color,
      barWidth: 2.4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
