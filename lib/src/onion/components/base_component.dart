import 'package:flutter/widgets.dart';

class BaseComponent extends StatelessWidget {
  final double x;
  final double y;
  final Widget child;

  const BaseComponent({
    super.key,
    required this.child,
    required this.x,
    required this.y,
  });

  @override
  Widget build(BuildContext context) =>
      Positioned(left: x, top: y, child: child);
}
