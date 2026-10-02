import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDsOUui-GnbX_NuXqMbYc6ygXP1F5GRxw",
      appId: "1:1000815020441:android:6e67da7e136bf5abaceb08",
      messagingSenderId: "1000815020441",
      projectId: "tapmine-app",
      storageBucket: "tapmine-app.firebasestorage.app",
    ),
  );
  runApp(const TapMineApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────

const bgDark = Color(0xFF070910);
const bgDark2 = Color(0xFF0B0F1A);
const cardDark = Color(0xFF111827);
const cardDark2 = Color(0xFF151C2C);
const amber = Color(0xFFFFC94D);
const amber2 = Color(0xFFFFA62B);
const purple = Color(0xFF8B5CF6);
const cyan = Color(0xFF22D3EE);
const green = Color(0xFF34D399);
const red = Color(0xFFF87171);
const blue = Color(0xFF60A5FA);

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: amber,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0D121E),
          indicatorColor: amber.withOpacity(.16),
          height: 72,
          labelTextStyle: MaterialStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const RootScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────

class Package {
  final String id, title, subtitle;
  final int cost;
  final double multiplier;
  final Duration duration;
  final IconData icon;
  final Color color;

  const Package(
    this.id,
    this.title,
    this.subtitle,
    this.cost,
    this.multiplier,
    this.duration,
    this.icon,
    this.color,
  );
}

const packages = [
  Package(
    'daily',
    'Daily Booster',
    '24 hours • 1.5x',
    500,
    1.5,
    Duration(hours: 24),
    Icons.wb_sunny_rounded,
    Color(0xFF34D399),
  ),
  Package(
    'weekly',
    'Weekly Booster',
    '7 days • 2x',
    3000,
    2.0,
    Duration(days: 7),
    Icons.rocket_launch_rounded,
    Color(0xFF60A5FA),
  ),
  Package(
    'monthly',
    'Monthly Booster',
    '30 days • 3x',
    10000,
    3.0,
    Duration(days: 30),
    Icons.diamond_rounded,
    Color(0xFFF472B6),
  ),
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
  final String id, title, desc;
  final int bonus;
  final IconData icon;
  final Color color;
  final bool Function(double, int, int) check;

  const Achievement(
    this.id,
    this.title,
    this.desc,
    this.bonus,
    this.icon,
    this.color,
    this.check,
  );
}

final achievementsList = [
  Achievement(
    'points_1000',
    'Rising Miner',
    '1000 lifetime points kamao',
    200,
    Icons.trending_up_rounded,
    green,
    (lp, rc, sc) => lp >= 1000,
  ),
  Achievement(
    'points_5000',
    'Power Miner',
    '5000 lifetime points kamao',
    500,
    Icons.flash_on_rounded,
    blue,
    (lp, rc, sc) => lp >= 5000,
  ),
  Achievement(
    'points_20000',
    'Mining Legend',
    '20000 lifetime points kamao',
    2000,
    Icons.workspace_premium_rounded,
    Color(0xFFF472B6),
    (lp, rc, sc) => lp >= 20000,
  ),
  Achievement(
    'referrals_1',
    'First Friend',
    '1 dost refer karo',
    100,
    Icons.person_add_alt_1_rounded,
    purple,
    (lp, rc, sc) => rc >= 1,
  ),
  Achievement(
    'referrals_5',
    'Community Builder',
    '5 dost refer karo',
    1000,
    Icons.groups_rounded,
    amber2,
    (lp, rc, sc) => rc >= 5,
  ),
  Achievement(
    'streak_7',
    'Consistent Miner',
    '7 din lagatar app kholo',
    500,
    Icons.local_fire_department_rounded,
    red,
    (lp, rc, sc) => sc >= 7,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// ROOT
// ─────────────────────────────────────────────────────────────────────────────

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int tabIndex = 0;
  String? uid, shortId, referredBy;

  double points = 0;
  double lifetimePoints = 0;
  int referralCount = 0;
  int streakCount = 0;
  Set<String> claimedAchievements = {};

  int adsWatchedToday = 0;
  bool adMilestoneClaimed = false;
  bool telegramTaskDone = false;

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
      (chainActive && chainStage >= 1)
          ? boostChain[chainStage - 1].multiplier
          : 1.0;

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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (snap.exists) {
        final data = snap.data()!;

        points = (data['points'] ?? 0).toDouble();
        lifetimePoints =
            (data['lifetimePoints'] ?? points).toDouble();
        referredBy = data['referredBy'];
        referralCount = (data['referralCount'] ?? 0) as int;
        streakCount = (data['streakCount'] ?? 0) as int;
        telegramTaskDone = (data['telegramTaskDone'] ?? false) as bool;

        claimedAchievements =
            ((data['claimedAchievements'] as List?) ?? [])
                .cast<String>()
                .toSet();

        final mult = (data['packageMultiplier'] ?? 1.0).toDouble();
        final expiresTs = data['packageExpiresAt'];

        if (expiresTs is Timestamp &&
            expiresTs.toDate().isAfter(DateTime.now())) {
          packageMultiplier = mult;
          packageExpiresAt = expiresTs.toDate();
        }

        DateTime? adDate;
        if (data['adCounterDate'] is Timestamp) {
          final d = (data['adCounterDate'] as Timestamp).toDate();
          adDate = DateTime(d.year, d.month, d.day);
        }

        if (adDate != null && adDate.isAtSameMomentAs(today)) {
          adsWatchedToday = (data['adsWatchedToday'] ?? 0) as int;
          adMilestoneClaimed =
              (data['adMilestoneClaimed'] ?? false) as bool;
        } else {
          adsWatchedToday = 0;
          adMilestoneClaimed = false;
        }

        DateTime? lastDate;
        if (data['lastLoginDate'] is Timestamp) {
          final d = (data['lastLoginDate'] as Timestamp).toDate();
          lastDate = DateTime(d.year, d.month, d.day);
        }

        if (lastDate == null || lastDate.isBefore(today)) {
          if (lastDate != null &&
              today.difference(lastDate).inDays == 1) {
            streakCount += 1;
          } else {
            streakCount = 1;
          }

          final bonus =
              streakBonusTable[(streakCount - 1) % 7];

          dailyBonus = bonus;
          points += bonus;
          lifetimePoints += bonus;

          await userDoc!.update({
            'lastLoginDate': Timestamp.fromDate(today),
            'streakCount': streakCount,
            'points': points,
            'lifetimePoints': lifetimePoints,
            'adCounterDate': Timestamp.fromDate(today),
            'adsWatchedToday': adsWatchedToday,
            'adMilestoneClaimed': adMilestoneClaimed,
          });
        }
      } else {
        streakCount = 1;
        dailyBonus = streakBonusTable[0];
        points = dailyBonus.toDouble();
        lifetimePoints = points;

        await userDoc!.set({
          'points': points,
          'lifetimePoints': lifetimePoints,
          'shortId': shortId,
          'referredBy': null,
          'referralCount': 0,
          'packageMultiplier': 1.0,
          'packageExpiresAt': null,
          'streakCount': streakCount,
          'lastLoginDate':
              Timestamp.fromDate(today),
          'claimedAchievements': <String>[],
          'adCounterDate': Timestamp.fromDate(today),
          'adsWatchedToday': 0,
          'adMilestoneClaimed': false,
          'telegramTaskDone': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Offline/local UI can still load.
    }

    if (!mounted) return;

    setState(() => loading = false);

    if (dailyBonus != null) {
      final b = dailyBonus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            backgroundColor: cardDark2,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Text(
              '🔥 Day $streakCount streak! +$b points mile',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (!mounted) return;

    setState(() {
      final earned = displayHashrate / 1000;
      points += earned;
      lifetimePoints += earned;

      if (chainActive) {
        chainSecondsLeft--;

        if (chainSecondsLeft <= 0) {
          chainActive = false;
          if (chainStage >= boostChain.length) {
            chainStage = 0;
          }
        }
      }

      if (packageExpiresAt != null &&
          DateTime.now().isAfter(packageExpiresAt!)) {
        packageMultiplier = 1.0;
        packageExpiresAt = null;
        userDoc?.update({
          'packageMultiplier': 1.0,
          'packageExpiresAt': null,
        });
      }
    });

    secondsSinceSave++;

    if (secondsSinceSave >= 5) {
      secondsSinceSave = 0;
      userDoc?.update({
        'points': points,
        'lifetimePoints': lifetimePoints,
      });
    }
  }

  void watchAdForNextStage() {
    setState(() {
      if (chainStage >= boostChain.length) {
        chainStage = 0;
      }

      chainStage += 1;
      chainSecondsLeft =
          boostChain[chainStage - 1].seconds;
      chainActive = true;
      adsWatchedToday += 1;
    });

    userDoc?.update({
      'adsWatchedToday': adsWatchedToday,
    });
  }

  Future<String?> claimAdMilestone() async {
    if (adMilestoneClaimed) {
      return 'Pehle hi le chuke ho';
    }

    if (adsWatchedToday < adMilestoneTarget) {
      return 'Abhi aur ads dekho';
    }

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
      'claimedAchievements':
          FieldValue.arrayUnion([ach.id]),
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    userDoc?.update({
      'points': points,
      'lifetimePoints': lifetimePoints,
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: bgDark,
        body: Center(
          child: _LoadingLogo(),
        ),
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
      extendBody: true,
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: amber.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: amber.withOpacity(.25),
                ),
              ),
              child: const Icon(
                Icons.memory_rounded,
                color: amber,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'TapMine',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: .2,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'REWARDS',
              style: TextStyle(
                color: amber.withOpacity(.85),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: green.withOpacity(.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: green.withOpacity(.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: green, size: 7),
                SizedBox(width: 6),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    color: green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: screens[tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) {
          setState(() => tabIndex = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory_rounded),
            label: 'Mine',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt_rounded),
            label: 'Boost',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard_rounded),
            label: 'Rank',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME
// ─────────────────────────────────────────────────────────────────────────────

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
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atFinalStage =
        widget.chainStage >= boostChain.length;

    final canWatchNext =
        !widget.chainActive && !atFinalStage;

    final stageColor =
        widget.chainStage >= 1
            ? boostChain[widget.chainStage - 1].color
            : amber;

    final progress = widget.chainActive
        ? widget.chainSecondsLeft /
            boostChain[widget.chainStage - 1].seconds
        : 0.0;

    return Stack(
      children: [
        const _AmbientBackground(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            110,
          ),
          child: Column(
            children: [
              _BalanceStrip(
                points: widget.points,
                multiplier: widget.packageMultiplier,
              ),
              const SizedBox(height: 14),

              // Main mining core
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  18,
                  24,
                  18,
                  20,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      stageColor.withOpacity(.16),
                      purple.withOpacity(.10),
                      const Color(0xFF0D1422),
                    ],
                  ),
                  border: Border.all(
                    color: stageColor.withOpacity(.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: stageColor.withOpacity(.06),
                      blurRadius: 35,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _MiningOrb(
                      color: stageColor,
                      active: widget.chainActive,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.hashrate} H/s',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'MINING POWER',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.42),
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (widget.packageMultiplier > 1 &&
                        widget.packageExpiresAt != null)
                      _TinyPill(
                        icon: Icons.bolt_rounded,
                        text:
                            '${widget.packageMultiplier}x booster active',
                        color: green,
                      ),

                    if (widget.chainActive) ...[
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: stageColor,
                            size: 17,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'STAGE ${widget.chainStage}/${boostChain.length}',
                            style: TextStyle(
                              color: stageColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: .7,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '• ${boostChain[widget.chainStage - 1].multiplier}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fmt(widget.chainSecondsLeft),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0).toDouble(),
                          minHeight: 7,
                          backgroundColor:
                              Colors.white.withOpacity(.07),
                          valueColor:
                              AlwaysStoppedAnimation(stageColor),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.chainStage < boostChain.length
                            ? 'Next ${boostChain[widget.chainStage].multiplier}x'
                            : 'Final boost stage',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.45),
                          fontSize: 11,
                        ),
                      ),
                    ] else if (canWatchNext) ...[
                      const SizedBox(height: 18),
                      _GlowButton(
                        color:
                            boostChain[widget.chainStage].color,
                        icon: Icons.play_circle_fill_rounded,
                        text: widget.chainStage == 0
                            ? 'WATCH AD • START BOOST'
                            : 'WATCH AD • UNLOCK NEXT BOOST',
                        subtext:
                            '${boostChain[widget.chainStage].multiplier}x for ${_fmt(boostChain[widget.chainStage].seconds)}',
                        onTap: widget.onWatchAd,
                      ),
                    ] else ...[
                      const SizedBox(height: 18),
                      _CompleteBanner(
                        text:
                            'Boost chain complete! Dobara shuru karo.',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Referral
              _GlassCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _IconBox(
                          icon: Icons.people_alt_rounded,
                          color: purple,
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invite & Earn',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Apna code share karo aur rewards lo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.shortId != null)
                          Text(
                            '+50',
                            style: TextStyle(
                              color: green,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: purple.withOpacity(.08),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: purple.withOpacity(.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.shortId ?? '--------',
                              style: const TextStyle(
                                color: purple,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Share',
                            onPressed: () {
                              Share.share(
                                'TapMine Rewards mein mere saath join karo! Mera referral code: ${widget.shortId}',
                              );
                            },
                            icon: const Icon(
                              Icons.share_rounded,
                              color: purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.referredBy != null)
                      _SuccessRow(
                        text:
                            'Referral applied: ${widget.referredBy}',
                      )
                    else
                      Column(
                        children: [
                          TextField(
                            controller: codeController,
                            textCapitalization:
                                TextCapitalization.characters,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter referral code',
                              prefixIcon: const Icon(
                                Icons.link_rounded,
                              ),
                              filled: true,
                              fillColor:
                                  Colors.white.withOpacity(.035),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: purple,
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(13),
                                ),
                              ),
                              onPressed: applying
                                  ? null
                                  : () async {
                                      setState(() {
                                        applying = true;
                                        message = null;
                                      });

                                      final err =
                                          await widget
                                              .onApplyReferral(
                                        codeController.text,
                                      );

                                      if (!mounted) return;

                                      setState(() {
                                        applying = false;
                                        message = err ??
                                            'Bonus points mil gaye!';
                                      });
                                    },
                              child: applying
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'APPLY CODE',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          if (message != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              message!,
                              style: TextStyle(
                                color: message ==
                                        'Bonus points mil gaye!'
                                    ? green
                                    : red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'TapMine is a rewards game. Real crypto mining nahi hoti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(.28),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PACKAGES
// ─────────────────────────────────────────────────────────────────────────────

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
    return Stack(
      children: [
        const _AmbientBackground(),
        ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            110,
          ),
          children: [
            const _PageHeading(
              eyebrow: 'POWER CENTER',
              title: 'Boost your mining',
              subtitle:
                  'Use points to activate temporary multipliers.',
            ),
            const SizedBox(height: 16),

            _PointsHero(
              points: widget.points,
              multiplier: widget.activeMultiplier,
              expiry: widget.activeExpiresAt,
            ),

            const SizedBox(height: 18),

            if (message != null)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 12),
                child: _MessageBanner(
                  message: message!,
                  color: message == 'Package activate ho gaya!'
                      ? green
                      : red,
                ),
              ),

            for (int i = 0; i < packages.length; i++)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 13),
                child: _PackageCard(
                  pkg: packages[i],
                  featured: i == 2,
                  disabled: buying,
                  onBuy: () async {
                    setState(() {
                      buying = true;
                      message = null;
                    });

                    final err =
                        await widget.onBuy(packages[i]);

                    if (!mounted) return;

                    setState(() {
                      buying = false;
                      message =
                          err ?? 'Package activate ho gaya!';
                    });
                  },
                ),
              ),

            const SizedBox(height: 2),
            Text(
              'Points-based packages hain. Real-money packages baad mein add kiye ja sakte hain.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.28),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASKS
// ─────────────────────────────────────────────────────────────────────────────

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
    final nextStreakBonus =
        streakBonusTable[widget.streakCount % 7];

    final adProgress =
        widget.adsWatchedToday
            .clamp(0, adMilestoneTarget);

    return Stack(
      children: [
        const _AmbientBackground(),
        ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            110,
          ),
          children: [
            const _PageHeading(
              eyebrow: 'DAILY MISSIONS',
              title: 'Earn more points',
              subtitle:
                  'Complete simple tasks every day.',
            ),
            const SizedBox(height: 16),

            _StreakTaskHero(
              streak: widget.streakCount,
              nextBonus: nextStreakBonus,
            ),

            const SizedBox(height: 16),

            _TaskCardNew(
              icon: Icons.ondemand_video_rounded,
              color: amber2,
              title: '$adMilestoneTarget Boost Ads',
              subtitle:
                  '$adProgress/$adMilestoneTarget completed',
              reward: '+$adMilestoneBonus',
              progress:
                  adProgress / adMilestoneTarget,
              action: widget.adMilestoneClaimed
                  ? const _DoneBadge()
                  : _TaskButton(
                      label: 'CLAIM',
                      color: amber2,
                      enabled:
                          adProgress >=
                              adMilestoneTarget,
                      onTap: () async {
                        final err =
                            await widget
                                .onClaimAdMilestone();

                        if (!mounted) return;

                        setState(() {
                          message =
                              err ?? 'Claim ho gaya!';
                        });
                      },
                    ),
            ),

            _TaskCardNew(
              icon: Icons.send_rounded,
              color: blue,
              title: 'Join Telegram',
              subtitle: widget.telegramTaskDone
                  ? 'Reward already collected'
                  : 'One-time community reward',
              reward: '+100',
              progress: null,
              action: widget.telegramTaskDone
                  ? const _DoneBadge()
                  : _TaskButton(
                      label: 'CLAIM',
                      color: blue,
                      onTap: () =>
                          widget.onClaimTelegram(),
                    ),
            ),

            _TaskCardNew(
              icon: Icons.calendar_month_rounded,
              color: green,
              title: 'Daily Check-in',
              subtitle:
                  'Current streak: ${widget.streakCount} days',
              reward: '+$nextStreakBonus',
              progress: 1,
              action: const _DoneBadge(),
            ),

            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: green,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARDS
// ─────────────────────────────────────────────────────────────────────────────

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
    final nextBonus =
        streakBonusTable[streakCount % 7];

    return Stack(
      children: [
        const _AmbientBackground(),
        ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            110,
          ),
          children: [
            const _PageHeading(
              eyebrow: 'REWARDS',
              title: 'Your achievements',
              subtitle:
                  'Milestones unlock extra points.',
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFB93845),
                    Color(0xFFE8782D),
                    Color(0xFF6F2B4D),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: red.withOpacity(.12),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streakCount DAY STREAK',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Kal wapas aao • +$nextBonus points',
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(.82),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Lifetime',
                    value:
                        lifetimePoints.toStringAsFixed(0),
                    color: amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.people_alt_rounded,
                    title: 'Referrals',
                    value: '$referralCount',
                    color: purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            const Text(
              'ACHIEVEMENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),

            for (final ach in achievementsList)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 10),
                child: _AchievementCardNew(
                  achievement: ach,
                  unlocked: ach.check(
                    lifetimePoints,
                    referralCount,
                    streakCount,
                  ),
                  claimed:
                      claimedAchievements.contains(ach.id),
                  onClaim: () => onClaim(ach),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEADERBOARD
// ─────────────────────────────────────────────────────────────────────────────

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  static const medalColors = [
    Color(0xFFFFD700),
    Color(0xFFC0C0C0),
    Color(0xFFCD7F32),
  ];

  @override
  Widget build(BuildContext context) {
    final myUid =
        FirebaseAuth.instance.currentUser?.uid;

    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .limit(20);

    return Stack(
      children: [
        const _AmbientBackground(),
        StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: amber,
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Abhi koi data nahi hai',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                110,
              ),
              children: [
                const _PageHeading(
                  eyebrow: 'GLOBAL RANK',
                  title: 'Leaderboard',
                  subtitle:
                      'Top miners by current points.',
                ),
                const SizedBox(height: 18),

                if (docs.length >= 3)
                  _Podium(
                    docs: docs.take(3).toList(),
                    myUid: myUid,
                  ),

                const SizedBox(height: 18),

                for (int i = docs.length >= 3 ? 3 : 0;
                    i < docs.length;
                    i++)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 9),
                    child: _RankRow(
                      rank: i + 1,
                      doc: docs[i],
                      isMe: docs[i].id == myUid,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE UI
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _GlowCircle(
              color: purple,
              size: 260,
            ),
          ),
          Positioned(
            top: 180,
            left: -120,
            child: _GlowCircle(
              color: cyan,
              size: 220,
            ),
          ),
          Positioned(
            bottom: 50,
            right: -100,
            child: _GlowCircle(
              color: amber,
              size: 240,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowCircle({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.035),
            blurRadius: 100,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

class _LoadingLogo extends StatelessWidget {
  const _LoadingLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: amber.withOpacity(.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: amber.withOpacity(.25),
            ),
          ),
          child: const Icon(
            Icons.memory_rounded,
            color: amber,
            size: 44,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'TAPMINE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            color: amber,
            backgroundColor: Colors.white12,
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}

class _BalanceStrip extends StatelessWidget {
  final double points;
  final double multiplier;

  const _BalanceStrip({
    required this.points,
    required this.multiplier,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallBalance(
            icon: Icons.account_balance_wallet_rounded,
            label: 'BALANCE',
            value: points.toStringAsFixed(2),
            color: amber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SmallBalance(
            icon: Icons.bolt_rounded,
            label: 'MULTIPLIER',
            value: '${multiplier.toStringAsFixed(1)}x',
            color:
                multiplier > 1 ? green : purple,
          ),
        ),
      ],
    );
  }
}

class _SmallBalance extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _SmallBalance({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(.055),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.38),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiningOrb extends StatelessWidget {
  final Color color;
  final bool active;

  const _MiningOrb({
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(.35),
            color.withOpacity(.08),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(active ? .30 : .12),
            blurRadius: active ? 38 : 25,
            spreadRadius: active ? 5 : 0,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(.28),
                cardDark2,
              ],
            ),
            border: Border.all(
              color: color.withOpacity(.65),
              width: 1.5,
            ),
          ),
          child: Icon(
            active
                ? Icons.bolt_rounded
                : Icons.memory_rounded,
            color: color,
            size: 37,
          ),
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text, subtext;
  final VoidCallback onTap;

  const _GlowButton({
    required this.color,
    required this.icon,
    required this.text,
    required this.subtext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.black),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtext,
                        style: TextStyle(
                          color: Colors.black.withOpacity(.62),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark.withOpacity(.92),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: Colors.white.withOpacity(.055),
        ),
      ),
      child: child,
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(.18),
        ),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _TinyPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteBanner extends StatelessWidget {
  final String text;

  const _CompleteBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: green.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: green.withOpacity(.16),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_rounded,
            color: green,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: green,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final String text;

  const _SuccessRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: green.withOpacity(.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: green,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;

  const _PageHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: amber,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(.42),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _PointsHero extends StatelessWidget {
  final double points, multiplier;
  final DateTime? expiry;

  const _PointsHero({
    required this.points,
    required this.multiplier,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            amber.withOpacity(.16),
            purple.withOpacity(.12),
            cardDark,
          ],
        ),
        border: Border.all(
          color: amber.withOpacity(.17),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: amber.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: amber,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AVAILABLE POINTS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.38),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  points.toStringAsFixed(2),
                  style: const TextStyle(
                    color: amber,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (multiplier > 1 && expiry != null)
            _TinyPill(
              icon: Icons.bolt_rounded,
              text: '${multiplier}x',
              color: green,
            ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Package pkg;
  final bool featured, disabled;
  final VoidCallback onBuy;

  const _PackageCard({
    required this.pkg,
    required this.featured,
    required this.disabled,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: pkg.color.withOpacity(
            featured ? .38 : .14,
          ),
        ),
        boxShadow: featured
            ? [
                BoxShadow(
                  color: pkg.color.withOpacity(.06),
                  blurRadius: 25,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pkg.color.withOpacity(.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pkg.icon,
                  color: pkg.color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pkg.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (featured) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: pkg.color
                                  .withOpacity(.13),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              'MAX',
                              style: TextStyle(
                                color: pkg.color,
                                fontSize: 7,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pkg.subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '${pkg.multiplier}x',
                    style: TextStyle(
                      color: pkg.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'BOOST',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${pkg.cost} points',
                  style: TextStyle(
                    color: pkg.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: disabled ? null : onBuy,
                  style: FilledButton.styleFrom(
                    backgroundColor: pkg.color,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ACTIVATE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakTaskHero extends StatelessWidget {
  final int streak, nextBonus;

  const _StreakTaskHero({
    required this.streak,
    required this.nextBonus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF532535),
            Color(0xFF742F36),
            Color(0xFF252033),
          ],
        ),
        border: Border.all(
          color: red.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: red.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFF7043),
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak DAY STREAK',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kal check-in karo • +$nextBonus points',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.62),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCardNew extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, reward;
  final double? progress;
  final Widget action;

  const _TaskCardNew({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.progress,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withOpacity(.13),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: color),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    reward,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'POINTS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              action,
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0).toDouble(),
                minHeight: 5,
                backgroundColor:
                    Colors.white.withOpacity(.06),
                valueColor:
                    AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _TaskButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding:
              const EdgeInsets.symmetric(horizontal: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding:
          const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: green.withOpacity(.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: green.withOpacity(.18),
        ),
      ),
      child: const Icon(
        Icons.check_rounded,
        color: green,
        size: 18,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCardNew extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked, claimed;
  final VoidCallback onClaim;

  const _AchievementCardNew({
    required this.achievement,
    required this.unlocked,
    required this.claimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final active = unlocked || claimed;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: claimed
              ? green.withOpacity(.28)
              : unlocked
                  ? a.color.withOpacity(.25)
                  : Colors.white.withOpacity(.045),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: (claimed ? green : a.color)
                  .withOpacity(active ? .12 : .045),
              shape: BoxShape.circle,
            ),
            child: Icon(
              claimed
                  ? Icons.check_circle_rounded
                  : a.icon,
              color: claimed
                  ? green
                  : active
                      ? a.color
                      : Colors.grey,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: active
                        ? Colors.white
                        : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  a.desc,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${a.bonus} points',
                  style: TextStyle(
                    color: a.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (claimed)
            const _DoneBadge()
          else if (unlocked)
            _TaskButton(
              label: 'CLAIM',
              color: a.color,
              onTap: onClaim,
            )
          else
            const Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey,
              size: 19,
            ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<QueryDocumentSnapshot<
      Map<String, dynamic>>> docs;
  final String? myUid;

  const _Podium({
    required this.docs,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final order = [1, 0, 2];

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: [
        for (final index in order)
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4),
              child: _PodiumItem(
                doc: docs[index],
                rank: index + 1,
                isMe: docs[index].id == myUid,
                height: index == 0
                    ? 165
                    : index == 1
                        ? 140
                        : 125,
              ),
            ),
          ),
      ],
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final QueryDocumentSnapshot<
      Map<String, dynamic>> doc;
  final int rank;
  final bool isMe;
  final double height;

  const _PodiumItem({
    required this.doc,
    required this.rank,
    required this.isMe,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFFC0C0C0),
      Color(0xFFFFD700),
      Color(0xFFCD7F32),
    ];

    final color = colors[rank - 1];
    final pts =
        (doc.data()['points'] ?? 0).toDouble();

    return Container(
      height: height,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(.22),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 1.5,
              ),
            ),
            child: Icon(
              rank == 1
                  ? Icons.emoji_events_rounded
                  : Icons.person_rounded,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '#$rank',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'User ${doc.id.substring(0, 6)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isMe ? amber : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            pts.toStringAsFixed(0),
            style: const TextStyle(
              color: amber,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final QueryDocumentSnapshot<
      Map<String, dynamic>> doc;
  final bool isMe;

  const _RankRow({
    required this.rank,
    required this.doc,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final pts =
        (doc.data()['points'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? amber.withOpacity(.08)
            : cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isMe
              ? amber.withOpacity(.25)
              : Colors.white.withOpacity(.045),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMe ? amber : Colors.grey,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: purple.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: purple,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'User ${doc.id.substring(0, 8)}${isMe ? " • YOU" : ""}',
              style: TextStyle(
                color: isMe ? amber : Colors.white,
                fontWeight:
                    isMe ? FontWeight.w900 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            pts.toStringAsFixed(2),
            style: const TextStyle(
              color: amber,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final String message;
  final Color color;

  const _MessageBanner({
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withOpacity(.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            message.contains('kam') ||
                    message.contains('nahi')
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
