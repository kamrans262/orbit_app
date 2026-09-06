import 'package:flutter/material.dart';

import '../../../../core/design_system/orbit_spacing.dart';
import '../../../../core/widgets/orbit_atmosphere_background.dart';

class CircleScreenScaffold extends StatelessWidget {
  const CircleScreenScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.bottom,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: actions,
        bottom: bottom,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const OrbitAtmosphereBackground(),
          SafeArea(top: false, child: body),
        ],
      ),
    );
  }
}

class CircleContentPadding extends StatelessWidget {
  const CircleContentPadding({
    required this.child,
    this.bottom = OrbitSpacing.xxl,
    super.key,
  });

  final Widget child;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700
            ? OrbitSpacing.xxl
            : OrbitSpacing.md;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                OrbitSpacing.md,
                horizontal,
                bottom,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
