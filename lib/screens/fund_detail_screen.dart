import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.schemeName)),
      body: Center(
        child: Text(
          'Ready to fetch data for Code: ${widget.schemeCode}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
