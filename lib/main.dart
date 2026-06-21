import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'design/tokens.dart';
import 'providers/rcon_provider.dart';
import 'screens/connect_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait-up on mobile, allow any orientation on desktop.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Dark system UI to match our theme.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: CS2Colors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const CS2RconPanelApp());
}

class CS2RconPanelApp extends StatelessWidget {
  const CS2RconPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RconProvider(),
      child: MaterialApp(
        title: 'CS2 RCON Panel',
        debugShowCheckedModeBanner: false,

        // ── Dark theme only (CS2 aesthetic) ──────────
        theme: CS2Theme.dark,
        darkTheme: CS2Theme.dark,
        themeMode: ThemeMode.dark,

        // ── Entry point ──────────────────────────────
        home: const ConnectScreen(),

        // ── Global error handler ─────────────────────
        builder: (context, child) {
          return MediaQuery(
            // Prevent font scaling from breaking layouts
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
