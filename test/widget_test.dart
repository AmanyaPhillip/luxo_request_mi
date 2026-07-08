import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:luxo_request_mi/main.dart';
import 'package:luxo_request_mi/providers/user_provider.dart';
import 'package:luxo_request_mi/providers/history_provider.dart';

void main() {
  testWidgets('LuxoApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LuxoApp());
    await tester.pump();
    // App starts either on SetupScreen or HomeScreen depending on prefs state.
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('AppWrapper shows loading indicator on first frame',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ],
        child: const MaterialApp(home: AppWrapper()),
      ),
    );
    // First frame shows the loading spinner while SharedPreferences loads.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
