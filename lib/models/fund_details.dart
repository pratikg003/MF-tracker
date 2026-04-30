import 'dart:convert';

class NavPoint {
  final String date;
  final double nav;

  NavPoint({required this.date, required this.nav});

  factory NavPoint.fromJson(Map<String, dynamic> json) {
    return NavPoint(date: json['date'], nav: double.tryParse(json['nav']) ?? 0);
  }

  Map<String, dynamic> toMap() {
    return {'date': date, 'nav': nav.toString()};
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
    final meta = json['meta'];

    var dataList = json['data'] as List;
    List<NavPoint> navPoints = dataList
        .map((i) => NavPoint.fromJson(i))
        .toList();
    return FundDetails(
      fundHouse: meta['fund_house'] ?? "Unkown",
      schemeCategory: meta['scheme_category'] ?? "Unkown",
      historicalData: navPoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fundHouse': fundHouse,
      'schemeCategory': schemeCategory,
      'historicalData': jsonEncode(
        historicalData.map((e) => e.toMap()).toList(),
      ),
    };
  }
}
