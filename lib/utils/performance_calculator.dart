import 'dart:math';

import 'package:mf_tracker/models/fund_details.dart';

class PerformanceCalculator {
  static DateTime _parseApiDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  static double? getReturnForPeriod(List<NavPoint> rawApiData, int yearsBack) {
    if(rawApiData.isEmpty) return null;

    final latestPoint = rawApiData.first;
    final latestDate = _parseApiDate(latestPoint.date);

    final targetDate = DateTime(latestDate.year - yearsBack, latestDate.month, latestDate.day);

    NavPoint? historicalPoint;

    for(var point in rawApiData){
      final pointDate = _parseApiDate(point.date);

      if(pointDate.isBefore(targetDate) || pointDate.isAtSameMomentAs(targetDate)) {
        historicalPoint = point;
        break;
      }
    }

    if(historicalPoint == null) return null;

    final double ratio = latestPoint.nav / historicalPoint.nav;
    final double power = 1.0/ yearsBack;
    final double cagr = (pow(ratio, power)-1)*100;

    return cagr;
  }
}
