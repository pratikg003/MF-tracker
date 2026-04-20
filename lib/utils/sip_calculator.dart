import 'dart:math';

class SipCalculator {
  static double calculateFutureValue({
    required double monthlyInvestment,
    required double annualReturnPercentage,
    required int years,
  }) {
    if (annualReturnPercentage == 0) {
      return monthlyInvestment * years * 12;
    }

    final double r = annualReturnPercentage / 12 / 100;

    final int n = years * 12;

    final double futureValue =
        monthlyInvestment * ((pow(1 + r, n) - 1) / r) * (1 + r);

    return futureValue;
  }
}
