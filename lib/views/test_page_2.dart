import 'package:flutter/material.dart';

/// Flutter code sample for [Scaffold].

class ScaffoldExampleApp2 extends StatelessWidget {
  const ScaffoldExampleApp2({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ScaffoldExample2());
  }
}

class ScaffoldExample2 extends StatefulWidget {
  const ScaffoldExample2({super.key});

  @override
  State<ScaffoldExample2> createState() => _ScaffoldExampleState2();
}

class _ScaffoldExampleState2 extends State<ScaffoldExample2> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sample Code')),
      body: Center(child: Text('You have pressed the button $_count times on page 2 or 4.')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}