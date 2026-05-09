import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mf_tracker/models/mutual_fund.dart';
import 'package:mf_tracker/screens/fund_detail_screen.dart';

class MfBrowserScreen extends StatefulWidget {
  const MfBrowserScreen({super.key});

  @override
  State<MfBrowserScreen> createState() => _MfBrowserScreenState();
}

class _MfBrowserScreenState extends State<MfBrowserScreen> {
  List<MutualFund> _allFunds = [];
  List<MutualFund> _filteredFunds = [];
  bool _isLoading = true;

  Future<void> fetchMasterList() async {
    final url = Uri.parse('https://api.mfapi.in/mf');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> decodedList = jsonDecode(response.body);

        final List<MutualFund> funds = decodedList
            .map((e) => MutualFund.fromJson(e))
            .toList();
        setState(() {
          _allFunds = funds;
          _filteredFunds = funds;
          _isLoading = false;
        });

        print('Total funds fetched: ${funds.length}');
      } else {
        print('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Network fetch failed with error: $e');
    }
  }

  void _runFilter(String enteredKeyword) {
    List<MutualFund> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allFunds;
    } else {
      results = _allFunds
          .where(
            (fund) => fund.schemeName.toLowerCase().contains(
              enteredKeyword.toLowerCase(),
            ),
          )
          .toList();
    }
    setState(() {
      _filteredFunds = results;
    });
  }

  @override
  void initState() {
    super.initState();

    fetchMasterList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MF Browser")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: TextField(
                    onChanged: (value) => _runFilter(value),
                    decoration: InputDecoration(
                      labelText: "Search Funds",
                      prefix: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredFunds.length,
                    itemBuilder: (context, index) {
                      final fund = _filteredFunds[index];
                      return ListTile(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FundDetailScreen(
                                schemeCode: fund.schemeCode,
                                schemeName: fund.schemeName,
                              ),
                            ),
                          );
                        },
                        title: Text(fund.schemeName),
                        subtitle: Text('Code: ${fund.schemeCode}'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
