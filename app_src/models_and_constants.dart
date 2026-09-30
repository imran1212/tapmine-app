import 'package:flutter/material.dart';

// --- Colors ---
const bgDark = Color(0xFF0B0E14);
const cardDark = Color(0xFF161B26);
const amber = Color(0xFFFFC94D);
const purple = Color(0xFF8B5CF6);
const green = Color(0xFF34D399);
const red = Color(0xFFF87171);

// --- Models ---
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

class BoostStage {
  final double multiplier;
  final int seconds;
  final Color color;
  const BoostStage(this.multiplier, this.seconds, this.color);
}

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

// --- Data Lists ---
const packages = [
  Package('daily', 'Daily Booster', '24 ghante · 1.5x', 500, 1.5,
      Duration(hours: 24), Icons.wb_sunny_rounded, Color(0xFF34D399)),
  Package('weekly', 'Weekly Booster', '7 din · 2x', 3000, 2.0,
      Duration(days: 7), Icons.rocket_launch_rounded, Color(0xFF60A5FA)),
  Package('monthly', 'Monthly Booster', '30 din · 3x', 10000, 3.0,
      Duration(days: 30), Icons.diamond_rounded, Color(0xFFF472B6)),
];

const boostChain = [
  BoostStage(1.5, 120, Color(0xFF34D399)),
  BoostStage(2.0, 90, Color(0xFF60A5FA)),
  BoostStage(3.5, 60, Color(0xFFF472B6)),
  BoostStage(5.0, 30, Color(0xFFFB923C)),
];

const streakBonusTable = [50, 100, 150, 200, 300, 400, 500];

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
