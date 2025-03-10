import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  final List<Widget> components;
  const BaseScreen(this.components, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: components);
  }
}
