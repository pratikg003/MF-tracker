import 'dart:convert';

class NavPoint {
  final String date;
  final double nav;

  NavPoint({required this.date, required this.nav});

  factory NavPoint.fromJson(Map<String, dynamic> json) {
    return NavPoint(
      date: json['date'] ?? 'Unknown',
      nav: double.tryParse(json['nav']?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'nav': nav.toString(),
    };
  }
}

class FundDetails {
  final String fundHouse;
  final String schemeCategory;
  final List<NavPoint> historicalData;

  FundDetails({
    required this.fundHouse,
    required this.schemeCategory,
    required this.historicalData,
  });

  factory FundDetails.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> meta = json['meta'] ?? {};
    
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];

    List<NavPoint> navPoints = dataList.map((i) => NavPoint.fromJson(i)).toList();

    return FundDetails(
      fundHouse: meta['fund_house'] ?? 'Unknown Fund',
      schemeCategory: meta['scheme_category'] ?? 'Defunct/Closed',
      historicalData: navPoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fundHouse': fundHouse,
      'schemeCategory': schemeCategory,
      'historicalData': jsonEncode(historicalData.map((e) => e.toMap()).toList()),
    };
  }
}