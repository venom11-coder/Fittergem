import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;



class PollingPage extends StatefulWidget {
  const PollingPage({super.key});

  @override
  _PollingPageState createState() => _PollingPageState();
}

class _PollingPageState extends State<PollingPage> {
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _pollLoginStatus();
  }

  Future<void> _pollLoginStatus() async {
    try {
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final response = await http.get(
          Uri.parse("https://<BACKEND-URL>/check-login-session"),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'logged_in') {
            setState(() {
              userId = data['user_id'];
              isLoading = false;
            });

            Navigator.pushNamedAndRemoveUntil(
              context,
              '/image_input',
                  (route) => false,
              arguments: userId,
            );
            return;
          }
        }
      }

      // Timeout
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login timed out.")));
      Navigator.pop(context);
    } catch (e) {
      print("Polling error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error checking login.")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: isLoading
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text("Waiting for login...", style: TextStyle(color: Colors.white)),
          ],
        )
            : const Text("Login failed", style: TextStyle(color: Colors.red)),
      ),
    );
  }
}
