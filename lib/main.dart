import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/user_provider.dart';
import 'providers/history_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LuxoApp());
}

class LuxoApp extends StatelessWidget {
  const LuxoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'LUXO Request',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            secondary: AppColors.goldDark,
            surface: AppColors.surfaceDark,
            background: AppColors.backgroundDeep,
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: AppColors.textLight,
            onBackground: AppColors.textLight,
          ),
          scaffoldBackgroundColor: AppColors.backgroundDeep,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.surfaceDark,
            foregroundColor: AppColors.gold,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            color: AppColors.surfaceDark,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderIdle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderIdle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            labelStyle: const TextStyle(color: AppColors.textMuted),
            hintStyle: const TextStyle(color: AppColors.textDisabled),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.surfaceDark,
            selectedItemColor: AppColors.gold,
            unselectedItemColor: AppColors.textDisabled,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const AppWrapper(),
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isLoading = true;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    // Load user data and check if setup is complete
    await userProvider.loadUserData();
    await historyProvider.loadHistory();

    setState(() {
      _isFirstTime = !userProvider.isSetupComplete;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD4AF37),
          ),
        ),
      );
    }

    // This logic ensures that if the user data is cleared (e.g., from settings),
    // the app will navigate back to the setup screen upon restart.
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isSetupComplete) {
          return const HomeScreen();
        } else {
          return const SetupScreen();
        }
      },
    );
  }
}