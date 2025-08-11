import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:campus_safe_app_admin_capstone/campus_security_admin/campus_security_admin_login.dart';
import 'package:campus_safe_app_admin_capstone/campus_security_admin/home_page.dart';
import 'package:campus_safe_app_admin_capstone/campus_security_admin/reports_screen.dart';
import 'package:campus_safe_app_admin_capstone/osa_admin/osa_homepage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: 'gemini.env');

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD1hd_ArzSNufP2RiehrN4qqLVoLoOs0Xs",
        authDomain: "campussafe-capstone.firebaseapp.com",
        databaseURL:
            "https://campussafe-capstone-default-rtdb.asia-southeast1.firebasedatabase.app",
        projectId: "campussafe-capstone",
        storageBucket: "campussafe-capstone.appspot.com",
        messagingSenderId: "347945595192",
        appId: "1:347945595192:web:6378f47f685c443c4ed1cd",
        measurementId: "G-JC184VLS9K",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginForm(),
        '/reports': (context) => const ReportsScreen(),
        '/home': (context) => const HomePage(),
        '/osa_homepage': (context) => const OsaHomePage(),
      },
      home: const ConnectivityWrapper(child: LoginForm()),
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final online = html.window.navigator.onLine;
      _isOffline = online == null ? false : !online;
      html.window.onOnline.listen((event) {
        setState(() {
          _isOffline = false;
        });
      });
      html.window.onOffline.listen((event) {
        setState(() {
          _isOffline = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.red.shade700,
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: const Text(
                  "No internet connection",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
