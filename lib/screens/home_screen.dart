import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mf_tracker/models/mutual_fund.dart';
import 'package:mf_tracker/providers/product_provider.dart';
import 'package:mf_tracker/utils/sip_calculator.dart';
import 'package:mf_tracker/widgets/allocation_chart.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> fetchMasterList() async {
    final url = Uri.parse('https://api.mfapi.in/mf');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> decodedList = jsonDecode(response.body);

        final List<MutualFund> funds = decodedList
            .map((e) => MutualFund.fromJson(e))
            .toList();
        print('Total funds fetched: ${funds.length}');
      } else {
        print('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Network fetch failed with error: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    final testResult = SipCalculator.calculateFutureValue(
      monthlyInvestment: 5000,
      annualReturnPercentage: 12,
      years: 10,
    );
    print('SIP Future Value: $testResult');

    fetchMasterList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadAndSyncData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Dashboard')),
      body: Center(
        child: Consumer<ProductProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.currentProduct == null) {
              return const CircularProgressIndicator();
            }

            if (provider.currentProduct != null) {
              final product = provider.currentProduct!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Target Asset Allocation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const AllocationChart(),

                  const SizedBox(height: 40),

                  Text(product.title, style: const TextStyle(fontSize: 24)),
                  Text(
                    '\$${product.price}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              );
            }

            return const Text('No internet and no cached data.');
          },
        ),
      ),
    );
  }
}
