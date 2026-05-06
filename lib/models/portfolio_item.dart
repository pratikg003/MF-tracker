class PortfolioItem {
  final int schemeCode;
  final String schemeName;
  final double totalInvested;
  final double totalUnits;

  double? liveNav;
  double? currentValue;

  PortfolioItem({
    required this.schemeCode,
    required this.schemeName,
    required this.totalInvested,
    required this.totalUnits,
    this.liveNav,
    this.currentValue
  });

  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      schemeCode: map['schemeCode'],
      schemeName: map['schemeName'],
      totalInvested: map['totalInvested'],
      totalUnits: map['totalUnits'],
    );  
  }
}
