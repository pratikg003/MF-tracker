import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AllocationChart extends StatelessWidget {
  const AllocationChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 60,
          sectionsSpace: 4,

          sections: [
            // 1. EQUITY
            PieChartSectionData(
              value: 60,
              color: Colors.blueAccent,
              title: '60%\nEquity', 
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
              ),
            ),

            // 2. DEBT
            PieChartSectionData(
              value: 30,
              color: Colors.deepOrangeAccent,
              title: '30%\nDebt',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
              ),
            ),

            // 3. GOLD
            PieChartSectionData(
              value: 10,
              color: Colors.green,
              title: '10%\nGold',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
              ),
            ),
          ]
        )
      ),
    );
  }
}