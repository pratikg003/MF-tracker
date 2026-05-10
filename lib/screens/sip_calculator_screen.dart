import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SipCalculatorScreen extends StatefulWidget {
  const SipCalculatorScreen({super.key});

  @override
  State<SipCalculatorScreen> createState() => _SipCalculatorScreenState();
}

class _SipCalculatorScreenState extends State<SipCalculatorScreen> {
  // Initial Values matching your Groww screenshot
  double _monthlyInvestment = 25000;
  double _expectedReturn = 12;
  double _timePeriodYears = 10;

  // Output Variables
  double _investedAmount = 0;
  double _estimatedReturns = 0;
  double _totalValue = 0;

  @override
  void initState() {
    super.initState();
    _calculateSip();
  }

  void _calculateSip() {
    int months = (_timePeriodYears * 12).toInt();
    double monthlyRate = _expectedReturn / 12 / 100;

    _investedAmount = _monthlyInvestment * months;

    // SIP Future Value Formula
    _totalValue =
        _monthlyInvestment *
        ((pow(1 + monthlyRate, months) - 1) / monthlyRate) *
        (1 + monthlyRate);

    _estimatedReturns = _totalValue - _investedAmount;
    setState(() {}); // Trigger UI update
  }

  // Helper widget for the sliders
  Widget _buildInputSection({
    required String title,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toInt()} $suffix',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.greenAccent,
          onChanged: (val) {
            onChanged(val);
            _calculateSip(); // Recalculate on every slide!
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SIP Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- INPUTS ---
            _buildInputSection(
              title: 'Monthly investment',
              value: _monthlyInvestment,
              min: 500,
              max: 100000,
              suffix: '₹',
              onChanged: (val) => _monthlyInvestment = val,
            ),
            _buildInputSection(
              title: 'Expected return rate (p.a)',
              value: _expectedReturn,
              min: 1,
              max: 30,
              suffix: '%',
              onChanged: (val) => _expectedReturn = val,
            ),
            _buildInputSection(
              title: 'Time period',
              value: _timePeriodYears,
              min: 1,
              max: 40,
              suffix: 'Yr',
              onChanged: (val) => _timePeriodYears = val,
            ),

            const SizedBox(height: 32),

            // --- THE DONUT CHART ---
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius:
                          70, // This hollows it out into a Donut!
                      sections: [
                        PieChartSectionData(
                          value: _investedAmount,
                          color: Colors.blue[100],
                          title: '',
                          radius: 30,
                        ),
                        PieChartSectionData(
                          value: _estimatedReturns,
                          color: Colors.blueAccent,
                          title: '',
                          radius: 30,
                        ),
                      ],
                    ),
                  ),
                  // Center Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Value',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '₹${_totalValue.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- RESULTS TEXT ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invested amount',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                Text(
                  '₹${_investedAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Est. returns',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                Text(
                  '₹${_estimatedReturns.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
