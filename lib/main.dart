import 'package:flutter/material.dart';
import 'package:mf_tracker/screens/portfolio_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MF Tracker',
      debugShowCheckedModeBanner: false,
      home: PortfolioScreen(),
    );
  }
}
