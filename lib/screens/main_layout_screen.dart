import 'package:flutter/material.dart';
import 'package:mf_tracker/screens/mf_browser_screen.dart';
import 'package:mf_tracker/screens/portfolio_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;

  final GlobalKey<PortfolioScreenState> _portfolioKey =
      GlobalKey<PortfolioScreenState>();

  late final List<Widget> _screens = [
    PortfolioScreen(key: _portfolioKey),
    const MfBrowserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 0) {
            _portfolioKey.currentState?.loadandCalculatePortfolio();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Browser',
          ),
        ],
      ),
    );
  }
}
