import 'package:flutter/material.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recommendations'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Alternatives'),
              Tab(text: 'Route Optimization'),
              Tab(text: 'Safety Stock'),
              Tab(text: 'Diversification'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AlternativesTab(),
            _RouteOptimizationTab(),
            _SafetyStockTab(),
            _DiversificationTab(),
          ],
        ),
      ),
    );
  }
}

class _AlternativesTab extends StatelessWidget {
  const _AlternativesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          title: Text('Supplier B'),
          subtitle: Text('Cost +3.4% • Risk -18%'),
        ),
        ListTile(
          title: Text('Supplier C'),
          subtitle: Text('Cost +1.1% • Risk -10%'),
        ),
      ],
    );
  }
}

class _RouteOptimizationTab extends StatelessWidget {
  const _RouteOptimizationTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          title: Text('Port Switch: Nhava Sheva → Chennai'),
          subtitle: Text('Transit +2 days, risk -26%'),
        ),
        ListTile(
          title: Text('Route Switch: Sea+Rail hybrid'),
          subtitle: Text('Cost +4.8%, reliability +18%'),
        ),
      ],
    );
  }
}

class _SafetyStockTab extends StatelessWidget {
  const _SafetyStockTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          title: Text('SKU-A'),
          subtitle: Text('Increase from 12 days to 18 days'),
        ),
        ListTile(
          title: Text('SKU-B'),
          subtitle: Text('Increase from 8 days to 11 days'),
        ),
      ],
    );
  }
}

class _DiversificationTab extends StatelessWidget {
  const _DiversificationTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          title: Text('Current concentration: 68% single region'),
          subtitle: Text('Target concentration: <45% in 2 quarters'),
        ),
        ListTile(
          title: Text('Action Plan'),
          subtitle: Text('Onboard 2 alternate suppliers in western corridor'),
        ),
      ],
    );
  }
}
