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
      children: <Widget>[
        InfoCard(
          title: 'LIVELLO SONORO LIVE',
          child: SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.stroke.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: dbaHistory.isEmpty ? const <FlSpot>[FlSpot(0, 0)] : dbaHistory,
                    isCurved: true,
                    color: AppTheme.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.green.withOpacity(0.15),
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
          child: SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.stroke.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: (fftBands.isEmpty ? List<double>.filled(16, 0) : fftBands)
                    .asMap()
                    .entries
                    .map((MapEntry<int, double> entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: entry.value,
                        width: 10,
                        color: AppTheme.cyan,
                        borderRadius: BorderRadius.circular(4),
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
          child: SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.stroke.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: <LineChartBarData>[
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
      spots: points.isEmpty ? const <FlSpot>[FlSpot(0, 0)] : points,
      isCurved: false,
      color: color,
      barWidth: 2.2,
      dotData: const FlDotData(show: false),
    );
  }
}