import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';

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
