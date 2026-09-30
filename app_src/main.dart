import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import 'models_and_constants.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

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
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'TapMine Rewards Pro',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: bgDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: amber,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: cardDark,
          indicatorColor: amber.withOpacity(0.25),
        ),
      ),
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
  double unclaimedPoints = 0;
  double maxStorageCap = 100.0;
  double lifetimePoints = 0;
  int referralCount = 0;
  int streakCount = 0;
  Set<String> claimedAchievements = {};

  int baseHashrate = 100;
  double packageMultiplier = 1.0;
  DateTime? packageExpiresAt;

  int chainStage = 0;
  int chainSecondsLeft = 0;
  bool chainActive = false;

  int adsWatchedToday = 0;
  final int adsTargetForMegaBoost = 5;

  Timer? timer;
  DocumentReference<Map<String, dynamic>>? userDoc;
  bool loading = true;
  int secondsSinceSave = 0;

  double get chainMultiplier =>
      (chainActive && chainStage >= 1) ? boostChain[chainStage - 1].multiplier : 1.0;

  int get displayHashrate =>
      (baseHashrate * chainMultiplier * packageMultiplier).round();

  @override
  void initState() {
    super.initState();
    _signInAndLoad();
  }

  Future<void> _signInAndLoad() async {
    int? dailyBonus;
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      uid = cred.user!.uid;
      shortId = uid!.substring(0, 8);
      userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userDoc!.get();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (snap.exists) {
        final data = snap.data()!;
        points = (data['points'] ?? 0).toDouble();
        unclaimedPoints = (data['unclaimedPoints'] ?? 0).toDouble();
        lifetimePoints = (data['lifetimePoints'] ?? points).toDouble();
        referredBy = data['referredBy'];
        referralCount = (data['referralCount'] ?? 0) as int;
        streakCount = (data['streakCount'] ?? 0) as int;
        adsWatchedToday = (data['adsWatchedToday'] ?? 0) as int;
        claimedAchievements =
            ((data['claimedAchievements'] as List?) ?? []).cast<String>().toSet();
        final mult = (data['packageMultiplier'] ?? 1.0).toDouble();
        final expiresTs = data['packageExpiresAt'];
        if (expiresTs is Timestamp && expiresTs.toDate().isAfter(DateTime.now())) {
          packageMultiplier = mult;
          packageExpiresAt = expiresTs.toDate();
        }
        DateTime? lastDate;
        if (data['lastLoginDate'] is Timestamp) {
          final d = (data['lastLoginDate'] as Timestamp).toDate();
          lastDate = DateTime(d.year, d.month, d.day);
        }
        if (lastDate == null || lastDate.isBefore(todayDate)) {
          if (lastDate != null && todayDate.difference(lastDate).inDays == 1) {
            streakCount += 1;
          } else {
            streakCount = 1;
          }
          adsWatchedToday = 0;
          final bonus = streakBonusTable[(streakCount - 1) % 7];
          dailyBonus = bonus;
          points += bonus;
          lifetimePoints += bonus;
          await userDoc!.update({
            'lastLoginDate': Timestamp.fromDate(todayDate),
            'streakCount': streakCount,
            'adsWatchedToday': 0,
            'points': points,
            'lifetimePoints': lifetimePoints,
          });
        }
      } else {
        streakCount = 1;
        dailyBonus = streakBonusTable[0];
        points = dailyBonus.toDouble();
        lifetimePoints = points;
        await userDoc!.set({
          'points': points,
          'unclaimedPoints': 0.0,
          'lifetimePoints': lifetimePoints,
          'shortId': shortId,
          'referredBy': null,
          'referralCount': 0,
          'adsWatchedToday': 0,
          'packageMultiplier': 1.0,
          'packageExpiresAt': null,
          'streakCount': streakCount,
          'lastLoginDate': Timestamp.fromDate(todayDate),
          'claimedAchievements': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Offline support
    }
    if (!mounted) return;
    setState(() => loading = false);
    if (dailyBonus != null) {
      final b = dailyBonus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            backgroundColor: cardDark,
            content: Text('🔥 Day $streakCount streak! +$b points mile'),
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {
      if (unclaimedPoints < maxStorageCap) {
        final earned = displayHashrate / 1000;
        unclaimedPoints = min(maxStorageCap, unclaimedPoints + earned);
      }

      if (chainActive) {
        chainSecondsLeft--;
        if (chainSecondsLeft <= 0) {
          chainActive = false;
          if (chainStage >= boostChain.length) chainStage = 0;
        }
      }
      if (packageExpiresAt != null && DateTime.now().isAfter(packageExpiresAt!)) {
        packageMultiplier = 1.0;
        packageExpiresAt = null;
        userDoc?.update({'packageMultiplier': 1.0, 'packageExpiresAt': null});
      }
    });
    secondsSinceSave++;
    if (secondsSinceSave >= 5) {
      secondsSinceSave = 0;
      userDoc?.update({
        'points': points,
        'unclaimedPoints': unclaimedPoints,
        'lifetimePoints': lifetimePoints,
        'adsWatchedToday': adsWatchedToday,
      });
    }
  }

  void claimMiningPoints(bool doubleReward) {
    if (unclaimedPoints <= 0) return;
    final gained = doubleReward ? unclaimedPoints * 2 : unclaimedPoints;
    setState(() {
      points += gained;
      lifetimePoints += gained;
      unclaimedPoints = 0;
    });
    userDoc?.update({
      'points': points,
      'unclaimedPoints': 0,
      'lifetimePoints': lifetimePoints,
    });
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: cardDark,
        content: Text(
            '${doubleReward ? "🎉 2x Claimed!" : "✅ Claimed"} +${gained.toStringAsFixed(2)} pts'),
      ),
    );
  }

  void watchAdForNextStage() {
    setState(() {
      if (chainStage >= boostChain.length) chainStage = 0;
      chainStage += 1;
      chainSecondsLeft = boostChain[chainStage - 1].seconds;
      chainActive = true;
      adsWatchedToday++;
    });
    _checkMegaBoostReward();
  }

  void _checkMegaBoostReward() {
    if (adsWatchedToday >= adsTargetForMegaBoost) {
      final expiry = DateTime.now().add(const Duration(hours: 2));
      setState(() {
        packageMultiplier = 3.0;
        packageExpiresAt = expiry;
        adsWatchedToday = 0;
      });
      userDoc?.update({
        'packageMultiplier': 3.0,
        'packageExpiresAt': Timestamp.fromDate(expiry),
        'adsWatchedToday': 0,
      });
      messengerKey.currentState?.showSnackBar(
        const SnackBar(
          backgroundColor: purple,
          content: Text('🚀 5 Ads Complete! 3x Mega Multiplier activated for 2 hours!'),
        ),
      );
    }
  }

  Future<String?> buyPackage(Package pkg) async {
    if (points < pkg.cost) return 'Points kam hain';
    final expiry = DateTime.now().add(pkg.duration);
    setState(() {
      points -= pkg.cost;
      packageMultiplier = pkg.multiplier;
      packageExpiresAt = expiry;
    });
    await userDoc?.update({
      'points': points,
      'packageMultiplier': pkg.multiplier,
      'packageExpiresAt': Timestamp.fromDate(expiry),
    });
    return null;
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
    await referrerRef.update({
      'points': FieldValue.increment(50),
      'lifetimePoints': FieldValue.increment(50),
      'referralCount': FieldValue.increment(1),
    });
    await userDoc!.update({
      'referredBy': code,
      'points': FieldValue.increment(25),
      'lifetimePoints': FieldValue.increment(25),
    });
    setState(() {
      referredBy = code;
      points += 25;
      lifetimePoints += 25;
    });
    return null;
  }

  Future<void> claimAchievement(Achievement ach) async {
    if (claimedAchievements.contains(ach.id)) return;
    if (!ach.check(lifetimePoints, referralCount, streakCount)) return;
    setState(() {
      points += ach.bonus;
      lifetimePoints += ach.bonus;
      claimedAchievements.add(ach.id);
    });
    await userDoc?.update({
      'points': points,
      'lifetimePoints': lifetimePoints,
      'claimedAchievements': FieldValue.arrayUnion([ach.id]),
    });
  }

  void addBonusPoints(double amount) {
    setState(() {
      points += amount;
      lifetimePoints += amount;
    });
    userDoc?.update({'points': points, 'lifetimePoints': lifetimePoints});
  }

  @override
  void dispose() {
    timer?.cancel();
    userDoc?.update({
      'points': points,
      'unclaimedPoints': unclaimedPoints,
      'lifetimePoints': lifetimePoints
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: bgDark,
        body: Center(child: CircularProgressIndicator(color: amber)),
      );
    }
    final screens = [
      HomeTab(
        hashrate: displayHashrate,
        points: points,
        unclaimedPoints: unclaimedPoints,
        maxStorageCap: maxStorageCap,
        shortId: shortId,
        referredBy: referredBy,
        chainStage: chainStage,
        chainActive: chainActive,
        chainSecondsLeft: chainSecondsLeft,
        packageMultiplier: packageMultiplier,
        packageExpiresAt: packageExpiresAt,
        adsWatchedToday: adsWatchedToday,
        adsTargetForMegaBoost: adsTargetForMegaBoost,
        onWatchAd: watchAdForNextStage,
        onClaimPoints: claimMiningPoints,
        onApplyReferral: applyReferral,
      ),
      SpinWheelTab(onRewardWon: addBonusPoints),
      PackagesTab(
        points: points,
        activeMultiplier: packageMultiplier,
        activeExpiresAt: packageExpiresAt,
        onBuy: buyPackage,
      ),
      RewardsTab(
        streakCount: streakCount,
        lifetimePoints: lifetimePoints,
        referralCount: referralCount,
        claimedAchievements: claimedAchievements,
        onClaim: claimAchievement,
        onWatchAdForBonus: () {
          addBonusPoints(50);
          setState(() => adsWatchedToday++);
          _checkMegaBoostReward();
        },
      ),
      const LeaderboardTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.memory, color: amber, size: 22),
            SizedBox(width: 8),
            Text('TapMine Rewards',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: screens[tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => setState(() => tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.memory_outlined), label: 'Mining'),
          NavigationDestination(
              icon: Icon(Icons.stars_outlined), label: 'Spin & Win'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), label: 'Packages'),
          NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined), label: 'Quests'),
          NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined), label: 'Ranks'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final int hashrate;
  final double points;
  final double unclaimedPoints;
  final double maxStorageCap;
  final String? shortId;
  final String? referredBy;
  final int chainStage;
  final bool chainActive;
  final int chainSecondsLeft;
  final double packageMultiplier;
  final DateTime? packageExpiresAt;
  final int adsWatchedToday;
  final int adsTargetForMegaBoost;
  final VoidCallback onWatchAd;
  final Function(bool doubleIt) onClaimPoints;
  final Future<String?> Function(String code) onApplyReferral;

  const HomeTab({
    super.key,
    required this.hashrate,
    required this.points,
    required this.unclaimedPoints,
    required this.maxStorageCap,
    required this.shortId,
    required this.referredBy,
    required this.chainStage,
    required this.chainActive,
    required this.chainSecondsLeft,
    required this.packageMultiplier,
    required this.packageExpiresAt,
    required this.adsWatchedToday,
    required this.adsTargetForMegaBoost,
    required this.onWatchAd,
    required this.onClaimPoints,
    required this.onApplyReferral,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final codeController = TextEditingController();
  String? message;
  bool applying = false;

  String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final atFinalStage = widget.chainStage >= boostChain.length;
    final canWatchNext = !widget.chainActive && !atFinalStage;
    Color stageColor =
        widget.chainStage >= 1 ? boostChain[widget.chainStage - 1].color : amber;
    final storageFull = widget.unclaimedPoints >= widget.maxStorageCap;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Wallet Balance:',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  Text('${widget.points.toStringAsFixed(2)} pts',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: amber)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [stageColor.withOpacity(0.18), purple.withOpacity(0.10)],
              ),
              border: Border.all(color: stageColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: stageColor.withOpacity(0.15)),
                  child: Icon(Icons.memory, size: 52, color: stageColor),
                ),
                const SizedBox(height: 12),
                Text('${widget.hashrate} H/s',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(storageFull ? '⚠️ Storage Full!' : 'Unclaimed Storage:',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: storageFull ? red : Colors.grey)),
                          Text(
                            '${widget.unclaimedPoints.toStringAsFixed(2)} / ${widget.maxStorageCap.toInt()} pts',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: widget.unclaimedPoints / widget.maxStorageCap,
                        color: storageFull ? red : green,
                        backgroundColor: Colors.white10,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.unclaimedPoints > 0
                                  ? () => widget.onClaimPoints(false)
                                  : null,
                              child: const Text('Claim 1x'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.black),
                              onPressed: widget.unclaimedPoints > 0
                                  ? () => widget.onClaimPoints(true)
                                  : null,
                              icon: const Icon(Icons.play_circle_fill, size: 16),
                              label: const Text('Claim 2x (Ad)',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🚀 Daily 3x Mega Boost Quest',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${widget.adsWatchedToday}/${widget.adsTargetForMegaBoost} Ads',
                              style: const TextStyle(
                                  fontSize: 12, color: amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: widget.adsWatchedToday / widget.adsTargetForMegaBoost,
                        color: amber,
                        backgroundColor: Colors.white10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.chainActive) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, color: stageColor, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Stage ${widget.chainStage}/${boostChain.length} · '
                        '${boostChain[widget.chainStage - 1].multiplier}x active',
                        style: TextStyle(
                            color: stageColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_fmt(widget.chainSecondsLeft),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canWatchNext ? amber : cardDark,
                      foregroundColor: canWatchNext ? Colors.black : Colors.white38,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: canWatchNext ? widget.onWatchAd : null,
                    icon: const Icon(Icons.play_circle_fill),
                    label: Text(
                      atFinalStage
                          ? 'Max Boost Active'
                          : widget.chainActive
                              ? 'Boost Active...'
                              : 'Watch Ad for Stage ${widget.chainStage + 1} Boost',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Referral Program',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Mera Code Share Karo (+50 pts for you):',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.shortId ?? '...',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: amber),
                        onPressed: () {
                          if (widget.shortId != null) {
                            Share.share('Mera TapMine referral code istemal karein: ${widget.shortId}');
                          }
                        },
                        icon: const Icon(Icons.share, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (widget.referredBy == null) ...[
                    const Text('Kisi ka referral code lagayein (+25 pts):',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              hintText: 'Enter code',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: applying
                              ? null
                              : () async {
                                  setState(() => applying = true);
                                  final err = await widget.onApplyReferral(codeController.text);
                                  setState(() {
                                    applying = false;
                                    message = err ?? 'Code apply ho gaya!';
                                  });
                                },
                          child: applying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Apply'),
                        )
                      ],
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 6),
                      Text(message!,
                          style: TextStyle(
                              fontSize: 12,
                              color: message!.contains('apply') ? green : red)),
                    ]
                  ] else ...[
                    Text('Referred by: ${widget.referredBy}',
                        style: const TextStyle(fontSize: 12, color: green)),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SpinWheelTab extends StatefulWidget {
  final Function(double bonus) onRewardWon;
  const SpinWheelTab({super.key, required this.onRewardWon});

  @override
  State<SpinWheelTab> createState() => _SpinWheelTabState();
}

class _SpinWheelTabState extends State<SpinWheelTab> {
  bool isSpinning = false;
  double lastWon = 0;

  void spinWheel() {
    setState(() => isSpinning = true);
    Future.delayed(const Duration(seconds: 2), () {
      final rewards = [50.0, 100.0, 150.0, 250.0, 500.0];
      final won = rewards[Random().nextInt(rewards.length)];
      widget.onRewardWon(won);
      if (!mounted) return;
      setState(() {
        isSpinning = false;
        lastWon = won;
      });
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          backgroundColor: purple,
          content: Text('🎉 Spin Reward: +$won Points!'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purple.withOpacity(0.15),
                border: Border.all(color: purple, width: 4),
              ),
              child: const Icon(Icons.stars_rounded, size: 100, color: amber),
            ),
            const SizedBox(height: 24),
            const Text('Lucky Ad Spin Wheel',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ad dekhein aur jackpot rewards win karein!',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: isSpinning ? null : spinWheel,
              icon: isSpinning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_circle_fill),
              label: Text(isSpinning ? 'Spinning...' : 'Watch Ad to Spin'),
            ),
            if (lastWon > 0) ...[
              const SizedBox(height: 20),
              Text('Last Win: +$lastWon Points',
                  style: const TextStyle(color: green, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }
}

class PackagesTab extends StatelessWidget {
  final double points;
  final double activeMultiplier;
  final DateTime? activeExpiresAt;
  final Future<String?> Function(Package pkg) onBuy;

  const PackagesTab({
    super.key,
    required this.points,
    required this.activeMultiplier,
    required this.activeExpiresAt,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, i) {
        final pkg = packages[i];
        final canAfford = points >= pkg.cost;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: pkg.color.withOpacity(0.2),
                  child: Icon(pkg.icon, color: pkg.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(pkg.subtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('${pkg.cost} pts',
                          style: const TextStyle(
                              color: amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? amber : Colors.grey.shade800,
                    foregroundColor: canAfford ? Colors.black : Colors.white38,
                  ),
                  onPressed: canAfford
                      ? () async {
                          final res = await onBuy(pkg);
                          if (res != null) {
                            messengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text(res)),
                            );
                          } else {
                            messengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text('${pkg.title} active ho gaya!')),
                            );
                          }
                        }
                      : null,
                  child: const Text('Buy'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RewardsTab extends StatelessWidget {
  final int streakCount;
  final double lifetimePoints;
  final int referralCount;
  final Set<String> claimedAchievements;
  final Function(Achievement ach) onClaim;
  final VoidCallback onWatchAdForBonus;

  const RewardsTab({
    super.key,
    required this.streakCount,
    required this.lifetimePoints,
    required this.referralCount,
    required this.claimedAchievements,
    required this.onClaim,
    required this.onWatchAdForBonus,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: red),
                    const SizedBox(width: 8),
                    Text('Daily Streak: $streakCount Days',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bonus for today: +${streakBonusTable[(streakCount - 1) % 7]} pts',
                  style: const TextStyle(color: green, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: purple.withOpacity(0.15),
          child: ListTile(
            leading: const Icon(Icons.ondemand_video, color: amber),
            title: const Text('Watch Ad Quest (+50 Pts)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Quick bonus points for watching video ad'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: amber, foregroundColor: Colors.black),
              onPressed: onWatchAdForBonus,
              child: const Text('Watch'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Achievements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...achievementsList.map((ach) {
          final isClaimed = claimedAchievements.contains(ach.id);
          final canClaim =
              !isClaimed && ach.check(lifetimePoints, referralCount, streakCount);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(ach.icon, color: ach.color),
              title: Text(ach.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${ach.desc}\nReward: +${ach.bonus} pts',
                  style: const TextStyle(fontSize: 12)),
              trailing: isClaimed
                  ? const Icon(Icons.check_circle, color: green)
                  : ElevatedButton(
                      onPressed: canClaim ? () => onClaim(ach) : null,
                      child: const Text('Claim'),
                    ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('lifetimePoints', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: amber));
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('Abhi koi users nahi hain.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final shortId = data['shortId'] ?? 'Unknown';
            final pts = (data['lifetimePoints'] ?? 0).toDouble();

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: index == 0
                      ? amber
                      : index == 1
                          ? Colors.grey.shade400
                          : index == 2
                              ? Colors.brown.shade300
                              : cardDark,
                  foregroundColor: index <= 2 ? Colors.black : Colors.white,
                  child: Text('#${index + 1}'),
                ),
                title: Text('User $shortId',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('${pts.toStringAsFixed(1)} pts',
                    style: const TextStyle(
                        color: amber, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}
