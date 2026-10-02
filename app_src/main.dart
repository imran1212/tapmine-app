import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

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

const bgDark = Color(0xFF0B0E14);
const cardDark = Color(0xFF161B26);
const amber = Color(0xFFFFC94D);
const purple = Color(0xFF8B5CF6);
const green = Color(0xFF34D399);
const red = Color(0xFFF87171);

class TapMineApp extends StatelessWidget {
  const TapMineApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'TapMine Rewards',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: bgDark,
        colorScheme: ColorScheme.fromSeed(seedColor: amber, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(backgroundColor: bgDark, elevation: 0, centerTitle: true),
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

class Package {
  final String id;
  final String title;
  final String subtitle;
  final int cost;
  final double multiplier;
  final Duration duration;
  final IconData icon;
  final Color color;
  const Package(this.id, this.title, this.subtitle, this.cost, this.multiplier,
      this.duration, this.icon, this.color);
}

const packages = [
  Package('daily', 'Daily Booster', '24 ghante · 1.5x', 500, 1.5,
      Duration(hours: 24), Icons.wb_sunny_rounded, Color(0xFF34D399)),
  Package('weekly', 'Weekly Booster', '7 din · 2x', 3000, 2.0,
      Duration(days: 7), Icons.rocket_launch_rounded, Color(0xFF60A5FA)),
  Package('monthly', 'Monthly Booster', '30 din · 3x', 10000, 3.0,
      Duration(days: 30), Icons.diamond_rounded, Color(0xFFF472B6)),
];

class BoostStage {
  final double multiplier;
  final int seconds;
  final Color color;
  const BoostStage(this.multiplier, this.seconds, this.color);
}

const boostChain = [
  BoostStage(1.5, 120, Color(0xFF34D399)),
  BoostStage(2.0, 90, Color(0xFF60A5FA)),
  BoostStage(3.5, 60, Color(0xFFF472B6)),
  BoostStage(5.0, 30, Color(0xFFFB923C)),
];

const streakBonusTable = [50, 100, 150, 200, 300, 400, 500];
const adMilestoneTarget = 3;
const adMilestoneBonus = 300;

class Achievement {
  final String id;
  final String title;
  final String desc;
  final int bonus;
  final IconData icon;
  final Color color;
  final bool Function(double lifetimePoints, int referralCount, int streakCount) check;
  const Achievement(this.id, this.title, this.desc, this.bonus, this.icon,
      this.color, this.check);
}

final achievementsList = [
  Achievement('points_1000', 'Rising Miner', '1000 lifetime points kamao', 200,
      Icons.trending_up, const Color(0xFF34D399), (lp, rc, sc) => lp >= 1000),
  Achievement('points_5000', 'Power Miner', '5000 lifetime points kamao', 500,
      Icons.flash_on, const Color(0xFF60A5FA), (lp, rc, sc) => lp >= 5000),
  Achievement('points_20000', 'Mining Legend', '20000 lifetime points kamao', 2000,
      Icons.workspace_premium, const Color(0xFFF472B6), (lp, rc, sc) => lp >= 20000),
  Achievement('referrals_1', 'First Friend', '1 dost refer karo', 100,
      Icons.person_add, purple, (lp, rc, sc) => rc >= 1),
  Achievement('referrals_5', 'Community Builder', '5 dost refer karo', 1000,
      Icons.groups, const Color(0xFFFB923C), (lp, rc, sc) => rc >= 5),
  Achievement('streak_7', 'Consistent Miner', '7 din lagatar app kholo', 500,
      Icons.local_fire_department, const Color(0xFFEF4444), (lp, rc, sc) => sc >= 7),
];

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
  double lifetimePoints = 0;
  int referralCount = 0;
  int streakCount = 0;
  Set<String> claimedAchievements = {};

  int adsWatchedToday = 0;
  bool adMilestoneClaimed = false;
  bool telegramTaskDone = false;
  DateTime? adCounterDate;

  int baseHashrate = 100;
  double packageMultiplier = 1.0;
  DateTime? packageExpiresAt;

  int chainStage = 0;
  int chainSecondsLeft = 0;
  bool chainActive = false;

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
        lifetimePoints = (data['lifetimePoints'] ?? points).toDouble();
        referredBy = data['referredBy'];
        referralCount = (data['referralCount'] ?? 0) as int;
        streakCount = (data['streakCount'] ?? 0) as int;
        telegramTaskDone = (data['telegramTaskDone'] ?? false) as bool;
        claimedAchievements =
            ((data['claimedAchievements'] as List?) ?? []).cast<String>().toSet();
        final mult = (data['packageMultiplier'] ?? 1.0).toDouble();
        final expiresTs = data['packageExpiresAt'];
        if (expiresTs is Timestamp && expiresTs.toDate().isAfter(DateTime.now())) {
          packageMultiplier = mult;
          packageExpiresAt = expiresTs.toDate();
        }

        DateTime? adDate;
        if (data['adCounterDate'] is Timestamp) {
          final d = (data['adCounterDate'] as Timestamp).toDate();
          adDate = DateTime(d.year, d.month, d.day);
        }
        if (adDate != null && adDate.isAtSameMomentAs(todayDate)) {
          adsWatchedToday = (data['adsWatchedToday'] ?? 0) as int;
          adMilestoneClaimed = (data['adMilestoneClaimed'] ?? false) as bool;
        } else {
          adsWatchedToday = 0;
          adMilestoneClaimed = false;
        }
        adCounterDate = todayDate;

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
          final bonus = streakBonusTable[(streakCount - 1) % 7];
          dailyBonus = bonus;
          points += bonus;
          lifetimePoints += bonus;
          await userDoc!.update({
            'lastLoginDate': Timestamp.fromDate(todayDate),
            'streakCount': streakCount,
            'points': points,
            'lifetimePoints': lifetimePoints,
            'adCounterDate': Timestamp.fromDate(todayDate),
            'adsWatchedToday': adsWatchedToday,
            'adMilestoneClaimed': adMilestoneClaimed,
          });
        }
      } else {
        streakCount = 1;
        dailyBonus = streakBonusTable[0];
        points = dailyBonus.toDouble();
        lifetimePoints = points;
        adCounterDate = todayDate;
        await userDoc!.set({
          'points': points,
          'lifetimePoints': lifetimePoints,
          'shortId': shortId,
          'referredBy': null,
          'referralCount': 0,
          'packageMultiplier': 1.0,
          'packageExpiresAt': null,
          'streakCount': streakCount,
          'lastLoginDate': Timestamp.fromDate(todayDate),
          'claimedAchievements': <String>[],
          'adCounterDate': Timestamp.fromDate(todayDate),
          'adsWatchedToday': 0,
          'adMilestoneClaimed': false,
          'telegramTaskDone': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Internet na ho to bhi app local chalti rahe
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
      final earned = displayHashrate / 1000;
      points += earned;
      lifetimePoints += earned;
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
      userDoc?.update({'points': points, 'lifetimePoints': lifetimePoints});
    }
  }

  void watchAdForNextStage() {
    setState(() {
      if (chainStage >= boostChain.length) chainStage = 0;
      chainStage += 1;
      chainSecondsLeft = boostChain[chainStage - 1].seconds;
      chainActive = true;
      adsWatchedToday += 1;
    });
    userDoc?.update({'adsWatchedToday': adsWatchedToday});
  }

  Future<String?> claimAdMilestone() async {
    if (adMilestoneClaimed) return 'Pehle hi le chuke ho';
    if (adsWatchedToday < adMilestoneTarget) return 'Abhi aur ads dekho';
    setState(() {
      points += adMilestoneBonus;
      lifetimePoints += adMilestoneBonus;
      adMilestoneClaimed = true;
    });
    await userDoc?.update({
      'points': points,
      'lifetimePoints': lifetimePoints,
      'adMilestoneClaimed': true,
    });
    return null;
  }

  Future<void> claimTelegramTask() async {
    if (telegramTaskDone) return;
    setState(() {
      points += 100;
      lifetimePoints += 100;
      telegramTaskDone = true;
    });
    await userDoc?.update({
      'points': points,
      'lifetimePoints': lifetimePoints,
      'telegramTaskDone': true,
    });
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

  @override
  void dispose() {
    timer?.cancel();
    userDoc?.update({'points': points, 'lifetimePoints': lifetimePoints});
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
        shortId: shortId,
        referredBy: referredBy,
        chainStage: chainStage,
        chainActive: chainActive,
        chainSecondsLeft: chainSecondsLeft,
        packageMultiplier: packageMultiplier,
        packageExpiresAt: packageExpiresAt,
        onWatchAd: watchAdForNextStage,
        onApplyReferral: applyReferral,
      ),
      PackagesTab(
        points: points,
        activeMultiplier: packageMultiplier,
        activeExpiresAt: packageExpiresAt,
        onBuy: buyPackage,
      ),
      TasksTab(
        streakCount: streakCount,
        adsWatchedToday: adsWatchedToday,
        adMilestoneClaimed: adMilestoneClaimed,
        telegramTaskDone: telegramTaskDone,
        onClaimAdMilestone: claimAdMilestone,
        onClaimTelegram: claimTelegramTask,
      ),
      RewardsTab(
        streakCount: streakCount,
        lifetimePoints: lifetimePoints,
        referralCount: referralCount,
        claimedAchievements: claimedAchievements,
        onClaim: claimAchievement,
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
            Text('TapMine Rewards', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: screens[tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => setState(() => tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.memory_outlined), label: 'Mining'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), label: 'Packages'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Rewards'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), label: 'Leaderboard'),
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
  final int chainStage;
  final bool chainActive;
  final int chainSecondsLeft;
  final double packageMultiplier;
  final DateTime? packageExpiresAt;
  final VoidCallback onWatchAd;
  final Future<String?> Function(String code) onApplyReferral;

  const HomeTab({
    super.key,
    required this.hashrate,
    required this.points,
    required this.shortId,
    required this.referredBy,
    required this.chainStage,
    required this.chainActive,
    required this.chainSecondsLeft,
    required this.packageMultiplier,
    required this.packageExpiresAt,
    required this.onWatchAd,
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
    final canWatchNext = !widget.chainActive && !(atFinalStage);
    Color stageColor =
        widget.chainStage >= 1 ? boostChain[widget.chainStage - 1].color : amber;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
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
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: stageColor.withOpacity(0.15)),
                  child: Icon(Icons.memory, size: 56, color: stageColor),
                ),
                const SizedBox(height: 18),
                Text('${widget.hashrate} H/s',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text('${widget.points.toStringAsFixed(3)} pts',
                    style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600)),
                if (widget.shortId != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                    child: Text('ID: ${widget.shortId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                ],
                if (widget.packageMultiplier > 1.0 && widget.packageExpiresAt != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: green.withOpacity(0.4)),
                    ),
                    child: Text(
                      '📦 ${widget.packageMultiplier}x package · ${widget.packageExpiresAt!.day}/${widget.packageExpiresAt!.month} tak',
                      style: const TextStyle(fontSize: 12, color: green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                if (widget.chainActive) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, color: stageColor, size: 18),
                      const SizedBox(width: 6),
                      Text('Stage ${widget.chainStage}/${boostChain.length} · ${boostChain[widget.chainStage - 1].multiplier}x active',
                          style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_fmt(widget.chainSecondsLeft), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: widget.chainSecondsLeft / boostChain[widget.chainStage - 1].seconds,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(stageColor),
                    ),
                  ),
                  if (widget.chainStage < boostChain.length) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Agla: ${boostChain[widget.chainStage].multiplier}x (${_fmt(boostChain[widget.chainStage].seconds)}) — khatam hote hi ad dekh kar unlock karo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    const Text('Ye aakhri stage hai! Khatam hone par chain reset ho jayegi.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ] else if (canWatchNext) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: boostChain[widget.chainStage].color,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: widget.onWatchAd,
                      icon: const Icon(Icons.play_circle_fill),
                      label: Text(widget.chainStage == 0
                          ? 'Ad dekho — ${boostChain[0].multiplier}x (${_fmt(boostChain[0].seconds)}) shuru karo'
                          : 'Ad dekho — ${boostChain[widget.chainStage].multiplier}x (${_fmt(boostChain[widget.chainStage].seconds)}) unlock karo'),
                    ),
                  ),
                  if (widget.chainStage > 0) ...[
                    const SizedBox(height: 8),
                    Text('${widget.chainStage}/${boostChain.length} stages complete kiye', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: const Text('🎉 Poori chain complete! Dobara shuru karne ke liye niche dekho',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: purple.withOpacity(0.25))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.card_giftcard_rounded, color: purple, size: 20),
                    SizedBox(width: 8),
                    Text('Apna referral code share karo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: purple.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text(widget.shortId ?? '', style: const TextStyle(fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.bold, color: purple)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    side: BorderSide(color: purple.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Share.share('TapMine Rewards mein mere saath join karo! Mera referral code: ${widget.shortId}');
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Code share karo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(20)),
            child: widget.referredBy != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: green, size: 18),
                      const SizedBox(width: 8),
                      Text('Referral code lag chuka hai: ${widget.referredBy}', style: const TextStyle(color: green)),
                    ],
                  )
                : Column(
                    children: [
                      const Text('Kisi ka referral code hai to yahan lagao', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: bgDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          hintText: 'Referral code',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: applying
                              ? null
                              : () async {
                                  setState(() {
                                    applying = true;
                                    message = null;
                                  });
                                  final err = await widget.onApplyReferral(codeController.text);
                                  setState(() {
                                    applying = false;
                                    message = err ?? 'Bonus points mil gaye!';
                                  });
                                },
                          child: applying
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Apply karo'),
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 8),
                        Text(message!, style: TextStyle(color: message == 'Bonus points mil gaye!' ? green : red)),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          Text('Ye ek rewards game hai. Is app mein real crypto mining nahi hoti.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class PackagesTab extends StatefulWidget {
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
  State<PackagesTab> createState() => _PackagesTabState();
}

class _PackagesTabState extends State<PackagesTab> {
  bool buying = false;
  String? message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [amber.withOpacity(0.2), purple.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text('Aapke Points', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(widget.points.toStringAsFixed(2), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: amber)),
              if (widget.activeMultiplier > 1.0 && widget.activeExpiresAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '📦 Active: ${widget.activeMultiplier}x · ${widget.activeExpiresAt!.day}/${widget.activeExpiresAt!.month}/${widget.activeExpiresAt!.year} tak',
                    style: const TextStyle(color: green, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent)),
          ),
        for (final pkg in packages)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(18), border: Border.all(color: pkg.color.withOpacity(0.3))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: pkg.color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(pkg.icon, color: pkg.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(pkg.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${pkg.cost} points', style: TextStyle(color: pkg.color, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: pkg.color, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: buying
                      ? null
                      : () async {
                          setState(() {
                            buying = true;
                            message = null;
                          });
                          final err = await widget.onBuy(pkg);
                          setState(() {
                            buying = false;
                            message = err ?? 'Package activate ho gaya!';
                          });
                        },
                  child: const Text('Khareedo'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('Ye points-based packages hain, real paisa nahi lagta. Real-money packages Play Store launch ke baad add honge.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class TasksTab extends StatefulWidget {
  final int streakCount;
  final int adsWatchedToday;
  final bool adMilestoneClaimed;
  final bool telegramTaskDone;
  final Future<String?> Function() onClaimAdMilestone;
  final Future<void> Function() onClaimTelegram;

  const TasksTab({
    super.key,
    required this.streakCount,
    required this.adsWatchedToday,
    required this.adMilestoneClaimed,
    required this.telegramTaskDone,
    required this.onClaimAdMilestone,
    required this.onClaimTelegram,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String? message;

  @override
  Widget build(BuildContext context) {
    final nextStreakBonus = streakBonusTable[widget.streakCount % 7];
    final adProgress = widget.adsWatchedToday.clamp(0, adMilestoneTarget);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Daily Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Roz nayi tasks, roz naye rewards', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 18),

        // Task 1: Daily check-in
        _TaskCard(
          icon: Icons.calendar_today_rounded,
          color: green,
          title: 'Daily Check-in',
          subtitle: 'Day ${widget.streakCount} streak · Kal milega +$nextStreakBonus',
          trailing: const Icon(Icons.check_circle, color: green),
          progress: null,
        ),

        // Task 2: Ad milestone
        _TaskCard(
          icon: Icons.ondemand_video_rounded,
          color: Colors.orangeAccent,
          title: '$adMilestoneTarget Boost-Ads Dekho',
          subtitle: '$adProgress/$adMilestoneTarget complete · Reward: +$adMilestoneBonus points',
          progress: adProgress / adMilestoneTarget,
          trailing: widget.adMilestoneClaimed
              ? const Icon(Icons.check_circle, color: green)
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: adProgress < adMilestoneTarget
                      ? null
                      : () async {
                          final err = await widget.onClaimAdMilestone();
                          setState(() => message = err ?? 'Claim ho gaya!');
                        },
                  child: const Text('Claim'),
                ),
        ),

        // Task 3: Social quest
        _TaskCard(
          icon: Icons.send_rounded,
          color: Colors.lightBlueAccent,
          title: 'Telegram Join Karo',
          subtitle: widget.telegramTaskDone ? 'Shukriya! Reward mil chuka hai' : 'One-time reward: +100 points',
          progress: null,
          trailing: widget.telegramTaskDone
              ? const Icon(Icons.check_circle, color: green)
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => widget.onClaimTelegram(),
                  child: const Text('Join & Claim'),
                ),
        ),

        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: green)),
        ],
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double? progress;
  final Widget trailing;

  const _TaskCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RewardsTab extends StatelessWidget {
  final int streakCount;
  final double lifetimePoints;
  final int referralCount;
  final Set<String> claimedAchievements;
  final Future<void> Function(Achievement ach) onClaim;

  const RewardsTab({
    super.key,
    required this.streakCount,
    required this.lifetimePoints,
    required this.referralCount,
    required this.claimedAchievements,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final nextBonus = streakBonusTable[streakCount % 7];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFFB923C)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text('$streakCount Din Streak', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Kal wapas aao: +$nextBonus points', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        for (final ach in achievementsList)
          _AchievementCard(
            achievement: ach,
            unlocked: ach.check(lifetimePoints, referralCount, streakCount),
            claimed: claimedAchievements.contains(ach.id),
            onClaim: () => onClaim(ach),
          ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final bool claimed;
  final VoidCallback onClaim;

  const _AchievementCard({required this.achievement, required this.unlocked, required this.claimed, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final ach = achievement;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: claimed ? green.withOpacity(0.4) : (unlocked ? ach.color.withOpacity(0.5) : Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (claimed ? green : ach.color).withOpacity(unlocked || claimed ? 0.18 : 0.06), shape: BoxShape.circle),
            child: Icon(claimed ? Icons.check_circle : ach.icon, color: claimed ? green : (unlocked ? ach.color : Colors.grey), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ach.title, style: TextStyle(fontWeight: FontWeight.bold, color: unlocked || claimed ? Colors.white : Colors.grey)),
                const SizedBox(height: 2),
                Text(ach.desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text('+${ach.bonus} points', style: TextStyle(fontSize: 12, color: ach.color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (claimed)
            const Icon(Icons.check_circle, color: green)
          else if (unlocked)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ach.color, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: onClaim,
              child: const Text('Claim'),
            )
          else
            const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  static const medalColors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final query = FirebaseFirestore.instance.collection('users').orderBy('points', descending: true).limit(20);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: amber));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Abhi koi data nahi hai', style: TextStyle(color: Colors.grey)));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final pts = (doc.data()['points'] ?? 0).toDouble();
            final isMe = doc.id == myUid;
            final isTop3 = index < 3;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? amber.withOpacity(0.12) : cardDark,
                borderRadius: BorderRadius.circular(16),
                border: isMe ? Border.all(color: amber.withOpacity(0.4)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTop3 ? medalColors[index].withOpacity(0.2) : purple.withOpacity(0.15),
                      border: Border.all(color: isTop3 ? medalColors[index] : purple, width: 1.5),
                    ),
                    child: Center(
                      child: isTop3
                          ? Icon(Icons.emoji_events, size: 16, color: medalColors[index])
                          : Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('User ${doc.id.substring(0, 8)}${isMe ? " (Aap)" : ""}',
                        style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.w500, color: isMe ? amber : Colors.white)),
                  ),
                  Text(pts.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: amber)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
