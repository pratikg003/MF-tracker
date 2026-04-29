import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mf_tracker/models/fund_details.dart';
import 'package:mf_tracker/utils/performance_calculator.dart';

class FundDetailScreen extends StatefulWidget {
  final int schemeCode;
  final String schemeName;

  const FundDetailScreen({
    super.key,
    required this.schemeCode,
    required this.schemeName,
  });

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  bool _isLoading = true;
  FundDetails? _fundDetails;

  Future<void> _fetchHistoricalData() async {
    final url = Uri.parse('https://api.mfapi.in/mf/${widget.schemeCode}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        setState(() {
          _fundDetails = FundDetails.fromJson(decodedData);
          _isLoading = false;
        });

        print('Fund House: ${_fundDetails!.fundHouse}');
        print(
          'Total historical days fetched: ${_fundDetails!.historicalData.length}',
        );

        final threeYearReturn = PerformanceCalculator.getReturnForPeriod(_fundDetails!.historicalData, 3);

        if (threeYearReturn != null) {
        print('3-Year CAGR: ${threeYearReturn.toStringAsFixed(2)}%');
      } else {
        print('Fund is less than 3 years old!');
      }
      }
    } catch (e) {
      print('Failed to fetch details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<FlSpot> _generateChartSpots() {
    if (_fundDetails == null) return [];

    final reversedData = _fundDetails!.historicalData.reversed.toList();

    final List<FlSpot> spots = [];

    for (int i = 0; i < reversedData.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversedData[i].nav));
    }

    return spots;
  }

  @override
  void initState() {
    super.initState();

    _fetchHistoricalData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.schemeName)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
                child: Column(
                  children: [
                    Text(
                      'Ready to fetch data for Code: ${widget.schemeCode}',
                      style: const TextStyle(fontSize: 18),
                    ),
            
                    const SizedBox(height: 40),
            
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
            
                          lineBarsData: [
                            LineChartBarData(
                              spots: _generateChartSpots(),
                              isCurved: true,
                              color: Colors.greenAccent,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.greenAccent.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ),
    );
  }
}
