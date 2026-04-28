import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mf_tracker/models/fund_details.dart';

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
      }
    } catch (e) {
      print('Failed to fetch details: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
          : Center(
              child: Text(
                'Ready to fetch data for Code: ${widget.schemeCode}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
    );
  }
}
