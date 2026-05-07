import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mf_tracker/database/database_helper.dart';
import 'package:mf_tracker/models/portfolio_item.dart';
import 'package:mf_tracker/utils/xirr_calculator.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<PortfolioItem> _portfolio = [];
  bool _isLoading = true;
  double _grandTotalInvested = 0.0;
  double _grandTotalCurrent = 0.0;

  double? _globalXirr;

  Future<void> _loadandCalculatePortfolio() async {
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

          final String latestNavString = decodedData['data'][0]['nav'];
          final double liveNav = double.tryParse(latestNavString) ?? 0.0;

          setState(() {
            item.liveNav = liveNav;
            item.currentValue = item.totalUnits * liveNav;
            tempCurrent += item.currentValue!;
            _grandTotalCurrent = tempCurrent;
          });
        }
      } catch (e) {
        print('Failed to fetch live NAV for ${item.schemeName}: $e');
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

  @override
  void initState() {
    super.initState();
    _loadandCalculatePortfolio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Portfolio')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(20),
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
                Expanded(
                  child: _portfolio.isEmpty
                      ? const Center(child: Text('No investments yet!'))
                      : ListView.builder(
                          itemCount: _portfolio.length,
                          itemBuilder: (context, index) {
                            final item = _portfolio[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  item.schemeName,
                                  maxLines: 1,
                                  overflow: TextOverflow
                                      .ellipsis, // Prevents giant names from breaking the UI
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Invested: ₹${item.totalInvested.toStringAsFixed(2)}\nUnits: ${item.totalUnits.toStringAsFixed(4)}',
                                ),
                                isThreeLine: true,

                                trailing: item.currentValue == null
                                    // If still fetching, show a tiny spinner in the corner
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    // If fetch is done, show the live data
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
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
