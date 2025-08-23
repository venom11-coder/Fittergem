import 'package:flutter/material.dart';
import 'Introduction/Introdpage1.dart';
import 'package:login_project/image_input/image_input.dart';
import 'package:login_project/Introduction/polling.dart';
import 'package:login_project/Meal_Review/meal_review_homepage.dart';
import 'package:login_project/image_input/bodymeasurements.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // if you're using Firebase
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateInitialRoutes: (String initialRouteName) {
        Uri uri = Uri.tryParse(initialRouteName) ?? Uri();

        // Check for deep link
        if (uri.scheme == 'fittergem' && uri.host == 'callback') {
          final userId = uri.queryParameters['user_id'];
          return [
            MaterialPageRoute(
              builder: (context) => const ImageInputPage(),
              settings: RouteSettings(arguments: userId),
            ),
          ];
        }


        // Default app start
        return [
          MaterialPageRoute(
            builder: (context) => const Introdpage1(),
          )
        ];
      },

      routes: {
        '/image_input': (context) => const ImageInputPage(),
        '/start': (context) => const Introdpage1(),
        '/polling': (context) => const PollingPage(),


      },
    );

  }
}

