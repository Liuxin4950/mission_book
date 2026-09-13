import 'package:flutter/material.dart';

/// Composition Root 由 Bootstrap 完成本地数据库恢复和依赖组装。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mission Book')),
        body: const Center(child: Text('Hello World!')),
      ),
    );
  }
}
