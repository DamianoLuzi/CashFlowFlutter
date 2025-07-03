import 'package:flutter/material.dart';
import 'package:flutterapp/repository/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/screens/home.dart';
import 'package:flutterapp/screens/login.dart';
import 'package:flutterapp/screens/signup.dart';
import 'package:flutterapp/viewmodels/budget_view_model.dart';
import 'package:flutterapp/viewmodels/category_view_model.dart';
import 'package:flutterapp/viewmodels/notification_helper.dart';
import 'package:flutterapp/viewmodels/profile_view_model.dart';
import 'package:flutterapp/viewmodels/transaction_view_model.dart';
import 'package:flutterapp/viewmodels/dashboard_view_model.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  tz.initializeTimeZones();
  await NotificationHelper.initialize();

  runApp(
    MultiProvider(
    providers: [
      Provider<AuthService>(create: (_) => AuthService()),
      ChangeNotifierProvider(create: (_) => CategoryViewModel()),
      ChangeNotifierProvider(create: (_) => TransactionViewModel()),
      ChangeNotifierProvider( create: (context) => 
          DashboardViewModel(Provider.of<TransactionViewModel>(context, listen: false),),
      ),
      ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ChangeNotifierProvider(create: (_) => BudgetViewModel()),
    ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return MaterialApp(
      title: 'ExpTrackPM Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(), 
      },
    );
  }
}