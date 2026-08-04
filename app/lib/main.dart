import 'package:flutter/material.dart';

void main() {
  runApp(const WanderlockApp());
}

/// Placeholder shell for phase F0.
///
/// Deliberately empty: design tokens, theming and routing are the deliverable
/// of F1. This exists only so the format, analyze, design-token and test gates
/// have a real project to run against. Anything drawn here would be thrown away.
class WanderlockApp extends StatelessWidget {
  const WanderlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Wanderlock', home: Scaffold());
  }
}
