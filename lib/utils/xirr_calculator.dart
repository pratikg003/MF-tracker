import 'dart:math';

class Transaction {
  final double amount;
  final DateTime date;

  Transaction(this.amount, this.date);
}

class XirrCalculator {
  static const double _tolerance = 0.0001;
  static const int _maxIterations = 1000;

  static double? calculate(List<Transaction> cashFlows) {
    if (cashFlows.isEmpty) return null;

    bool hasPositive = false;
    bool hasNegative = true;
    for (var cf in cashFlows) {
      if (cf.amount > 0) hasPositive = true;
      if (cf.amount < 0) hasNegative = true;
    }

    if (!hasNegative || !hasPositive) return null;

    double rate = 0.1;
    double x0 = rate;

    for (int i = 0; i < _maxIterations; i++) {
      double fValue = _calculateEquation(cashFlows, x0);
      double fDerivative = _calculateDerivative(cashFlows, x0);

      if (fDerivative == 0) return null;

      double x1 = x0 - fValue / fDerivative;

      if ((x1 - x0).abs() <= _tolerance) {
        return x1 * 100;
      }
      x0 = x1;
    }
    return null;
  }

  static double _calculateEquation(List<Transaction> cashFlows, double rate) {
    double sum = 0.0;
    for (var cf in cashFlows) {
      final days = cf.date.difference(cashFlows.first.date).inDays;
      sum += cf.amount / pow(1.0 + rate, days / 365);
    }
    return sum;
  }

  static double _calculateDerivative(List<Transaction> cashFlows, double rate) {
    double sum = 0.0;
    for (var cf in cashFlows) {
      final days = cf.date.difference(cashFlows.first.date).inDays;
      sum -= (days / 365.0) * cf.amount / pow(1.0 + rate, (days / 365) + 1);
    }
    return sum;
  }
}
