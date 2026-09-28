import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const TapMineApp());

class TapMineApp extends StatelessWidget {
  const TapMineApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double points = 0;
  int hashrate = 100;
  bool boosted = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => points += hashrate / 1000);
    });
  }

  void boost() {
    // Baad mein yahan rewarded ad aayega
    setState(() {
      boosted = true;
      hashrate = 200;
    });
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          boosted = false;
          hashrate = 100;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TapMine Rewards')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.memory, size: 90, color: Colors.amber),
              const SizedBox(height: 16),
              Text('$hashrate H/s',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Points: ${points.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: boosted ? null : boost,
                icon: const Icon(Icons.bolt),
                label: Text(boosted ? 'Boost active (2x)' : 'Boost 2x (30 sec)'),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ye ek rewards game hai. Is app mein real crypto mining nahi hoti.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
