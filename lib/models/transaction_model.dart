class FundTransaction {
  final int? id;
  final int schemeCode;
  final DateTime date;
  final double amount;
  final double nav;
  final double units;

  FundTransaction({
    this.id,
    required this.schemeCode,
    required this.date,
    required this.nav,
    required this.amount,
    required this.units,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schemeCode': schemeCode,
      'date': date.toIso8601String(),
      'amount': amount,
      'nav': nav,
      'units': units,
    };
  }

  factory FundTransaction.fromMap(Map<String, dynamic> map) {
    return FundTransaction(
      schemeCode: map['schemeCode'],
      date: DateTime.parse(map['date']),
      nav: map['nav'],
      amount: map['amount'],
      units: map['units'],
    );
  }
}
