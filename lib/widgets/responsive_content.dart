import 'package:flutter/material.dart';

/// Constrains and centers [child] on wide screens (tablets, large foldables,
/// desktop-sized web windows) so content doesn't stretch edge-to-edge.
/// On any normal phone width this is a no-op - it returns [child] unchanged.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 960,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= maxWidth) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
