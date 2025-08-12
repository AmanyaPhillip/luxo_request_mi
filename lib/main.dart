import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/user_provider.dart';
import 'providers/history_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

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
          // LUXO Place inspired color scheme - gold and dark theme
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37), // Luxurious gold
            secondary: Color(0xFFB8860B), // Darker gold
            surface: Color(0xFF1A1A1A), // Rich dark
            background: Color(0xFF0D0D0D), // Deep black
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: Color(0xFFE0E0E0), // Light text
            onBackground: Color(0xFFE0E0E0),
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            foregroundColor: Color(0xFFD4AF37),
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF1A1A1A),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD4AF37)),
            ),
            labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
            hintStyle: const TextStyle(color: Color(0xFF808080)),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            selectedItemColor: Color(0xFFD4AF37),
            unselectedItemColor: Color(0xFF808080),
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

    return _isFirstTime ? const SetupScreen() : const HomeScreen();
  }
}