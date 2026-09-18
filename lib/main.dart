import 'package:flutter/material.dart';
import 'sign_in.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AlkhidmatBloodCampApp());
}

class AlkhidmatBloodCampApp extends StatelessWidget {
  const AlkhidmatBloodCampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alkhidmat Blood Camp',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const StaffSignInScreen(),
    );
  }
}