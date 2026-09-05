import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/orbit_colors.dart';
import '../../core/design_system/orbit_radius.dart';
import '../../core/design_system/orbit_spacing.dart';

class OrbitShell extends StatelessWidget {
  const OrbitShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: OrbitBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: _goToBranch,
      ),
    );
  }
}

class OrbitBottomNavigation extends StatelessWidget {
  const OrbitBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const List<_OrbitDestination> _destinations = <_OrbitDestination>[
    _OrbitDestination('Home', Icons.home_rounded),
    _OrbitDestination('Circles', Icons.groups_2_outlined),
    _OrbitDestination('Camera', Icons.photo_camera_rounded),
    _OrbitDestination('Activity', Icons.notifications_none_rounded),
    _OrbitDestination('Profile', Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: OrbitColors.navigation,
        border: Border(top: BorderSide(color: OrbitColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OrbitSpacing.xs,
            OrbitSpacing.xs,
            OrbitSpacing.xs,
            OrbitSpacing.xs,
          ),
          child: Row(
            children: List<Widget>.generate(_destinations.length, (index) {
              final destination = _destinations[index];
              final isSelected = currentIndex == index;
              final isCamera = index == 2;

              return Expanded(
                child: _BottomDestination(
                  destination: destination,
                  isSelected: isSelected,
                  isCamera: isCamera,
                  onTap: () => onDestinationSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomDestination extends StatelessWidget {
  const _BottomDestination({
    required this.destination,
    required this.isSelected,
    required this.isCamera,
    required this.onTap,
  });

  final _OrbitDestination destination;
  final bool isSelected;
  final bool isCamera;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? OrbitColors.primary : OrbitColors.textMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: OrbitSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: isCamera ? 52 : 38,
                height: isCamera ? 52 : 38,
                decoration: BoxDecoration(
                  color: isCamera
                      ? OrbitColors.cameraButton
                      : (isSelected
                            ? OrbitColors.primary.withValues(alpha: 0.14)
                            : Colors.transparent),
                  borderRadius: BorderRadius.circular(
                    isCamera ? OrbitRadius.xl : OrbitRadius.lg,
                  ),
                  border: isCamera
                      ? Border.all(color: OrbitColors.borderStrong)
                      : null,
                  boxShadow: isCamera
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  destination.icon,
                  color: isCamera ? OrbitColors.cameraIcon : foreground,
                  size: isCamera ? 28 : 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitDestination {
  const _OrbitDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
