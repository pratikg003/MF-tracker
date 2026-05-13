import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mf_tracker/database/database_helper.dart';
import 'package:mf_tracker/models/portfolio_item.dart';
import 'package:mf_tracker/screens/fund_detail_screen.dart';
import 'package:mf_tracker/utils/xirr_calculator.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => PortfolioScreenState();
}

class PortfolioScreenState extends State<PortfolioScreen> {
  List<PortfolioItem> _portfolio = [];
  bool _isLoading = true;
  double _grandTotalInvested = 0.0;
  double _grandTotalCurrent = 0.0;

  double? _globalXirr;

  Future<void> loadandCalculatePortfolio() async {
    final items = await DatabaseHelper.instance.getPortfolioSummary();

    double tempInvested = 0;
    for (var item in items) {
      tempInvested += item.totalInvested;
    }

    setState(() {
      _portfolio = items;
      _grandTotalInvested = tempInvested;
      _isLoading = false;
    });

    double tempCurrent = 0;
    for (var item in _portfolio) {
      try {
        final url = Uri.parse('https://api.mfapi.in/mf/${item.schemeCode}');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final decodedData = jsonDecode(response.body);

          final List<dynamic> dataList = decodedData['data'] ?? [];

          if (dataList.isNotEmpty) {
            final String latestNavString = dataList[0]['nav'];
            final double liveNav = double.tryParse(latestNavString) ?? 0.0;

            setState(() {
              item.liveNav = liveNav;
              item.currentValue = item.totalUnits * liveNav;
              tempCurrent += item.currentValue!;
              _grandTotalCurrent = tempCurrent;
            });
          } else {
            setState(() {
              item.liveNav = 0.0;
              item.currentValue = 0.0;
            });
          }
        }
      } catch (e) {
        print('Failed to fetch live NAV for ${item.schemeName}: $e');
        setState(() {
          item.liveNav = 0.0;
          item.currentValue = 0.0;
        });
      }
    }
    final rawTransactions = await DatabaseHelper.instance.getAllTransactions();

    List<Transaction> cashFlows = rawTransactions.map((t) {
      return Transaction(-t['amount'], DateTime.parse(t['date']));
    }).toList();

    if (cashFlows.isNotEmpty && _grandTotalCurrent > 0) {
      cashFlows.add(Transaction(_grandTotalCurrent, DateTime.now()));

      setState(() {
        _globalXirr = XirrCalculator.calculate(cashFlows);
      });
    }
  }

  List<PieChartSectionData> _generatePieSections() {
    if (_portfolio.isEmpty || _grandTotalCurrent <= 0) return [];

    final List<Color> sectionColors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
    ];

    return List.generate(_portfolio.length, (index) {
      final item = _portfolio[index];
      final itemValue = item.currentValue ?? 0;

      final percentage = (itemValue / _grandTotalCurrent) * 100;

      return PieChartSectionData(
        color:
            sectionColors[index %
                sectionColors.length], 
        value: itemValue,
        title: percentage > 5
            ? '${percentage.toStringAsFixed(1)}%'
            : '', 
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    loadandCalculatePortfolio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Portfolio')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadandCalculatePortfolio,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Total Portfolio Value',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_grandTotalCurrent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Invested',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '₹${_grandTotalInvested.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Overall Return',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '₹${(_grandTotalCurrent - _grandTotalInvested).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          _grandTotalCurrent >=
                                              _grandTotalInvested
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'XIRR',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    _globalXirr == null
                                        ? '--%'
                                        : '${_globalXirr!.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: (_globalXirr ?? 0) >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Your Pie Chart
                  if (_portfolio.isNotEmpty && _grandTotalCurrent > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: _generatePieSections(),
                          ),
                        ),
                      ),
                    ),

                  if (_portfolio.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No investments yet!')),
                    )
                  else
                    ..._portfolio.map((item) {
                      final index = _portfolio.indexOf(item);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: [
                                    Colors.blueAccent,
                                    Colors.orangeAccent,
                                    Colors.purpleAccent,
                                    Colors.tealAccent,
                                    Colors.pinkAccent,
                                  ][index % 5],
                                ),
                              ),
                              title: Text(
                                item.schemeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Invested: ₹${item.totalInvested.toStringAsFixed(2)}\nUnits: ${item.totalUnits.toStringAsFixed(4)}',
                              ),
                              isThreeLine: true,
                              trailing: item.currentValue == null
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${item.currentValue!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'NAV: ₹${item.liveNav!.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),

                            const Divider(height: 1),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _showRedeemSheet(context, item),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Sell',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),

                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FundDetailScreen(
                                          schemeCode: item.schemeCode,
                                          schemeName: item.schemeName,
                                        ),
                                      ),
                                    ).then(
                                      (_) => loadandCalculatePortfolio(),
                                    ); // Refresh when coming back!
                                  },
                                  icon: const Icon(
                                    Icons.analytics_outlined,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Details',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  void _showRedeemSheet(BuildContext context, PortfolioItem item) {
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Redeem from ${item.schemeName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Currently Owned: ${item.totalUnits.toStringAsFixed(4)} units',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Redemption Amount (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) return;

                  if (item.liveNav == null || item.liveNav! <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please wait for live NAV to load."),
                      ),
                    );
                    return;
                  }

                  final unitsToRedeem = amount / item.liveNav!;

                  if (unitsToRedeem > item.totalUnits) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Insufficient units to redeem this amount.',
                        ),
                      ),
                    );
                    return;
                  }

                  await DatabaseHelper.instance.addRedemption(
                    schemeCode: item.schemeCode,
                    schemeName: item.schemeName,
                    amount: amount,
                    currentNav: item.liveNav!,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Redemption successful.')),
                    );

                    loadandCalculatePortfolio();
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Confirm Redemption',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
