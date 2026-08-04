import 'package:flutter/material.dart';

/// Deliberately misformatted. Valid Dart, wrong layout: this must be rejected
/// by the format gate before analyze even runs.
class    FormatProbe   extends StatelessWidget {
  const FormatProbe({super.key});
      @override
  Widget build(BuildContext context){return const SizedBox.shrink();}
}
