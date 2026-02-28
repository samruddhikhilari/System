import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final int step;

  const OnboardingScreen({super.key, required this.step});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.step);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                children: [
                  _buildOnboardingSlide(
                    title: 'See Your Entire Supply Chain',
                    description:
                        'Map every supplier from Tier-1 to Tier-N. Discover hidden dependencies.',
                    icon: Icons.map,
                  ),
                  _buildOnboardingSlide(
                    title: 'Predict Disruptions 14 Days Early',
                    description:
                        'AI models alert you before problems hit your business.',
                    icon: Icons.trending_down,
                  ),
                  _buildOnboardingSlide(
                    title: 'Simulate Cascading Impact',
                    description:
                        'Run what-if scenarios and see ripple effects across your supply chain.',
                    icon: Icons.call_split,
                  ),
                  _buildOnboardingSlide(
                    title: 'Act Fast With Smart Recommendations',
                    description:
                        'Get optimized suppliers, routes, and stock strategies.',
                    icon: Icons.lightbulb,
                  ),
                ],
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingSlide({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: const Color(0xFF4A90E2)),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == widget.step
                      ? const Color(0xFF4A90E2)
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.step < 3) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(widget.step < 3 ? 'Next' : 'Get Started'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
