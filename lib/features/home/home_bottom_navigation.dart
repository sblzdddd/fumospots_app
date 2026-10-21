import 'package:material_ui/material_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(240),
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: selectedIndex == 0 ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: const FaIcon(FontAwesomeIcons.house, size: 20),
              ),
              AnimatedScale(
                scale: selectedIndex == 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: const FaIcon(FontAwesomeIcons.solidHouse, size: 20),
              ),
            ],
          ),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: selectedIndex == 1 ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: const FaIcon(FontAwesomeIcons.user, size: 20),
              ),
              AnimatedScale(
                scale: selectedIndex == 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: const FaIcon(FontAwesomeIcons.solidUser, size: 20),
              ),
            ],
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
