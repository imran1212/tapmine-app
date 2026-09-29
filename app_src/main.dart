import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDsOUui-GnbX_NuXqkMbYc6ygXP1F5GRxw",
      appId: "1:1000815020441:android:6e67da7e136bf5abaceb08",
      messagingSenderId: "1000815020441",
      projectId: "tapmine-app",
      storageBucket: "tapmine-app.firebasestorage.app",
    ),
  );
  runApp(const TapMineApp());
}

class TapMineApp extends StatelessWidget {
  const TapMineApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TapMine Rewards',
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
  int boostLeft = 0;
  Timer? timer;
  String? uid;
  DocumentReference<Map<String, dynamic>>? userDoc;
  bool loading = true;
  int secondsSinceSave = 0;

  @override
  void initState() {
    super.initState();
    _signInAndLoad();
  }

  Future<void> _signInAndLoad() async {
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      uid = cred.user!.uid;
      userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userDoc!.get();
      if (snap.exists) {
        points = (snap.data()?['points'] ?? 0).toDouble();
      } else {
        await userDoc!.set({
          'points': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Internet na ho to bhi app local chalti rahe
    }
    if (!mounted) return;
    setState(() => loading = false);
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {
      points += hashrate / 1000;
      if (boosted) {
        boostLeft--;
        if (boostLeft <= 0) {
          boosted = false;
          hashrate = 100;
        }
      }
    });
    secondsSinceSave++;
    if (secondsSinceSave >= 5) {
      secondsSinceSave = 0;
      userDoc?.update({'points': points});
    }
  }

  void boost() {
    setState(() {
      boosted = true;
      hashrate = 200;
      boostLeft = 30;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    userDoc?.update({'points': points});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Points: ${points.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 8),
              if (uid != null)
                Text('ID: ${uid!.substring(0, 8)}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: boosted ? null : boost,
                icon: const Icon(Icons.bolt),
                label: Text(boosted
                    ? 'Boost active: ${boostLeft}s'
                    : 'Boost 2x (30 sec)'),
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
