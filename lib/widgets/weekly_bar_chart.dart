import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklyBarChart extends StatelessWidget {
  final bool isLoading;
  final List<double> percentList;
  final List<String> barLabels;

  const WeeklyBarChart({
    super.key,
    required this.isLoading,
    required this.percentList,
    required this.barLabels,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (percentList.isEmpty || barLabels.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('ยังไม่มีข้อมูลกราฟ')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F6),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.shade200.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'สรุปผลรายสัปดาห์',
            style: GoogleFonts.kanit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A3E42),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.brown.shade100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}%',
                        style: GoogleFonts.kanit(
                          fontSize: 12,
                          color: Colors.brown.shade700,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        if (value % 1 != 0) return const SizedBox.shrink();
                        final index = value.toInt();
                        if (index < 0 || index >= barLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          barLabels[index],
                          style: GoogleFonts.kanit(
                            fontSize: 11,
                            color: Colors.brown.shade700,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < percentList.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: percentList[i],
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4A5A5), Color(0xFF8C6E63)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
