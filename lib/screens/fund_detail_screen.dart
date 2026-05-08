import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mf_tracker/database/database_helper.dart';
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
  Map<int, double?> _performance = {};

  Future<void> _fetchHistoricalData() async {
    // 1. Load from Cache
    final cachedData = await DatabaseHelper.instance.getCachedFundDetails(
      widget.schemeCode,
    );
    if (cachedData != null) {
      _calculatePerformance(cachedData);
      setState(() {
        _fundDetails = cachedData;
        _isLoading = false;
      });
    }

    // 2. Fetch Fresh Data
    final url = Uri.parse('https://api.mfapi.in/mf/${widget.schemeCode}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final freshFundDetails = FundDetails.fromJson(decodedData);

        await DatabaseHelper.instance.cacheFundDetails(
          widget.schemeCode,
          freshFundDetails.toMap(),
        );
        _calculatePerformance(freshFundDetails);

        setState(() {
          _fundDetails = freshFundDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_fundDetails == null) setState(() => _isLoading = false);
    }
  }

  void _calculatePerformance(FundDetails details) {
    if (details.historicalData.isEmpty) return;
    _performance = {
      1: PerformanceCalculator.getReturnForPeriod(details.historicalData, 1),
      3: PerformanceCalculator.getReturnForPeriod(details.historicalData, 3),
      5: PerformanceCalculator.getReturnForPeriod(details.historicalData, 5),
    };
  }

  List<FlSpot> _generateChartSpots() {
    if (_fundDetails == null) return [];
    final reversedData = _fundDetails!.historicalData.reversed.toList();
    return List.generate(
      reversedData.length,
      (i) => FlSpot(i.toDouble(), reversedData[i].nav),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData();
  }

  Widget _buildStatItem(String label, int year) {
    final value = _performance[year];
    final color = (value ?? 0) >= 0 ? Colors.green : Colors.red;
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value == null ? '--' : '${value.toStringAsFixed(1)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fund Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fundDetails == null
          ? const Center(child: Text('Failed to load data.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Text(
                    _fundDetails!.fundHouse,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    widget.schemeName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${_fundDetails!.historicalData.first.nav.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'as of ${_fundDetails!.historicalData.first.date}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Performance Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('1Y Ret', 1),
                        _buildStatItem('3Y Ret', 3),
                        _buildStatItem('5Y Ret', 5),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Chart Section
                  if (_fundDetails!.historicalData.isEmpty)
                    const Center(child: Text('No historical data available.'))
                  else
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final date = _fundDetails!
                                      .historicalData
                                      .reversed
                                      .toList()[spot.x.toInt()]
                                      .date;
                                  return LineTooltipItem(
                                    '$date\n₹${spot.y}',
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                          ),
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
                                color: Colors.greenAccent.withAlpha(40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: _isLoading || _fundDetails == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showInvestSheet(context),
              label: const Text('Invest Now'),
              icon: const Icon(Icons.add_shopping_cart),
              backgroundColor: Colors.greenAccent,
            ),
    );
  }

  void _showInvestSheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter Investment Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                await DatabaseHelper.instance.addInvestment(
                  schemeCode: widget.schemeCode,
                  schemeName: widget.schemeName,
                  amount: amount,
                  currentNav: _fundDetails!.historicalData.first.nav,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Investment added to portfolio'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
