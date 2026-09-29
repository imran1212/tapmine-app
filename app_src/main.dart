import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

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
  await MobileAds.instance.initialize();
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
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int tabIndex = 0;
  String? uid;
  String? shortId;
  String? referredBy;
  double points = 0;
  int hashrate = 100;
  bool boosted = false;
  int boostLeft = 0;
  Timer? timer;
  DocumentReference<Map<String, dynamic>>? userDoc;
  bool loading = true;
  int secondsSinceSave = 0;

  RewardedAd? rewardedAd;
  bool adLoading = false;

  @override
  void initState() {
    super.initState();
    _signInAndLoad();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    adLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          adLoading = false;
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (error) {
          rewardedAd = null;
          adLoading = false;
          if (mounted) setState(() {});
        },
      ),
    );
  }

  Future<void> _signInAndLoad() async {
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      uid = cred.user!.uid;
      shortId = uid!.substring(0, 8);
      userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userDoc!.get();
      if (snap.exists) {
        points = (snap.data()?['points'] ?? 0).toDouble();
        referredBy = snap.data()?['referredBy'];
      } else {
        await userDoc!.set({
          'points': 0,
          'shortId': shortId,
          'referredBy': null,
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

  void watchAdToBoost() {
    if (rewardedAd == null) {
      if (!adLoading) _loadRewardedAd();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad tayyar nahi, dobara try karo')),
      );
      return;
    }
    final ad = rewardedAd!;
    rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) {
      setState(() {
        boosted = true;
        hashrate = 200;
        boostLeft = 30;
      });
    });
  }

  Future<String?> applyReferral(String code) async {
    code = code.trim();
    if (code.isEmpty) return 'Code khali hai';
    if (code == shortId) return 'Apna hi code nahi laga sakte';
    if (referredBy != null) return 'Pehle se ek code lag chuka hai';

    final q = await FirebaseFirestore.instance
        .collection('users')
        .where('shortId', isEqualTo: code)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return 'Ye code nahi mila';

    final referrerRef = q.docs.first.reference;
    await referrerRef.update({'points': FieldValue.increment(50)});
    await userDoc!.update({
      'referredBy': code,
      'points': FieldValue.increment(25),
    });
    setState(() {
      referredBy = code;
      points += 25;
    });
    return null;
  }

  @override
  void dispose() {
    timer?.cancel();
    userDoc?.update({'points': points});
    rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final screens = [
      HomeTab(
        hashrate: hashrate,
        points: points,
        shortId: shortId,
        referredBy: referredBy,
        boosted: boosted,
        boostLeft: boostLeft,
        onBoost: watchAdToBoost,
        onApplyReferral: applyReferral,
      ),
      const LeaderboardTab(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('TapMine Rewards')),
      body: screens[tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => setState(() => tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.memory), label: 'Mining'),
          NavigationDestination(
              icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final int hashrate;
  final double points;
  final String? shortId;
  final String? referredBy;
  final bool boosted;
  final int boostLeft;
  final VoidCallback onBoost;
  final Future<String?> Function(String code) onApplyReferral;

  const HomeTab({
    super.key,
    required this.hashrate,
    required this.points,
    required this.shortId,
    required this.referredBy,
    required this.boosted,
    required this.boostLeft,
    required this.onBoost,
    required this.onApplyReferral,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final codeController = TextEditingController();
  String? message;
  bool applying = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.memory, size: 90, color: Colors.amber),
          const SizedBox(height: 16),
          Text('${widget.hashrate} H/s',
              style:
                  const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Points: ${widget.points.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          if (widget.shortId != null)
            Text('ID: ${widget.shortId}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.boosted ? null : widget.onBoost,
            icon: const Icon(Icons.play_circle),
            label: Text(widget.boosted
                ? 'Boost active: ${widget.boostLeft}s'
                : 'Ad dekho, 2x Boost pao (30 sec)'),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Apna referral code share karo',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.shortId ?? '',
              style: const TextStyle(fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Share.share(
                  'TapMine Rewards mein mere saath join karo! Mera referral code: ${widget.shortId}');
            },
            icon: const Icon(Icons.share),
            label: const Text('Code share karo'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          if (widget.referredBy != null)
            Text('Referral code lag chuka hai: ${widget.referredBy}',
                style: const TextStyle(color: Colors.green))
          else ...[
            const Text('Kisi ka referral code hai to yahan lagao'),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Referral code',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: applying
                  ? null
                  : () async {
                      setState(() {
                        applying = true;
                        message = null;
                      });
                      final err =
                          await widget.onApplyReferral(codeController.text);
                      setState(() {
                        applying = false;
                        message = err ?? 'Bonus points mil gaye!';
                      });
                    },
              child: applying
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Apply karo'),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  style: TextStyle(
                      color: message == 'Bonus points mil gaye!'
                          ? Colors.green
                          : Colors.red)),
            ],
          ],
          const SizedBox(height: 32),
          const Text(
            'Ye ek rewards game hai. Is app mein real crypto mining nahi hoti.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .limit(20);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Abhi koi data nahi hai'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final pts = (doc.data()['points'] ?? 0).toDouble();
            final isMe = doc.id == myUid;
            return Card(
              color: isMe ? Colors.amber.withOpacity(0.15) : null,
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(
                    'User ${doc.id.substring(0, 8)}${isMe ? " (Aap)" : ""}'),
                trailing: Text(pts.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}
