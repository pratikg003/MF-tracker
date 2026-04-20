class MutualFund {
  final int schemeCode;
  final String schemeName;

  MutualFund({required this.schemeCode, required this.schemeName});

  factory MutualFund.fromJson(Map<String, dynamic> json) {
    return MutualFund(
      schemeCode: json['schemeCode'],
      schemeName: json['schemeName'],
    );
  }
}
