import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inno/app/router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: InnoGarageApp(),
    ),
  );
}

class InnoGarageApp extends StatelessWidget {
  const InnoGarageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'InnoGarage',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3: true,
      ),
    );
  }
}
