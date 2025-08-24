import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dart:convert';
import 'package:login_project/User_Info/user_data.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SignupPage extends StatefulWidget {

  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}
// if user clicks manual register
class _SignupPageState extends State<SignupPage> {
  final bool _obscurePassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;

      // gets full name and email
      String? fullname = user?.displayName;
      String? email = user?.email;


      UserData.fullname = fullname;
      UserData.email = email;
      if (user != null) {
        UserData.userId = user.uid;
      }

      print(fullname);
      print(email);

      // split the fullname to get first name for image input
      List<String> names = fullname?.split(' ') ?? [];
      String firstName = names.isNotEmpty ? names.first : "";
      String lastName = names.length > 1 ? names.sublist(1).join(" ") : "";

      if (user != null) {
        print(UserData.redirect);
        saveUserId(user.uid.toString());
        print("✅ Logged in as ${user.email}");
        Navigator.pushNamed(context, '/image_input', arguments: {
          'userID': user.uid.toString(),
          'firstname': firstName.toString()
        });
      }
    } catch (e) {
      print("❌ Login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In failed")),
      );
    }
  }

  Future<void> loginWithMicrosoft() async {
    try {
      final provider = OAuthProvider("microsoft.com");

// optional: if you're using an organization tenant
      provider.setCustomParameters({
        "tenant": ""
      });

      final userCredential = await FirebaseAuth.instance.signInWithProvider(
          provider);

// optional: get user info
      final user = userCredential.user;
      print("✅ Microsoft login: ${user?.email} | UID: ${user?.uid}");

      final user_microsoft = userCredential.user;
      final userId = user?.uid ?? "";
      final fullName = user?.displayName ?? "";
      final firstName = fullName
          .split(' ')
          .first;

      UserData.fullname = fullName;
      UserData.email = user?.email;
      if (user_microsoft != null) {
        print("✅ Microsoft login successful: ${user?.email}");

        if (user != null) {
          UserData.userId = user.uid;
          saveUserId(user.uid);// ✅ no ?
        }

        Navigator.pushNamed(context, '/image_input', arguments: {
          'userID': user?.uid,
          'firstname': firstName,
        });
      }
    } catch (e) {
      print("❌ Microsoft Login Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microsoft Sign-In failed")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            height: MediaQuery.of(context).size.height - 50,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(0.0),
                   child:  Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.purple),
                        onPressed: () {
                          Navigator.pop(context); // Go back to previous screen
                        },
                      ),
                    ),
                    ),

                    const SizedBox(height: 60.0),

                    const Text(
                      "Sign up",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Create your account",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    )
                  ],
                ),
                Column(
                  children: <Widget>[
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                          hintText: "Username",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.purple.withOpacity(0.1),
                          filled: true,
                          prefixIcon: const Icon(Icons.person)),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      decoration: InputDecoration(
                          hintText: "Email",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.purple.withOpacity(0.1),
                          filled: true,
                          prefixIcon: const Icon(Icons.email)),
                    ),


                    const SizedBox(height: 20),

                    TextField(
                      controller: _passwordController, // <-- Add this!
                      decoration: InputDecoration(
                        hintText: "Password",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none),
                        fillColor: Colors.purple.withOpacity(0.1),
                        filled: true,
                        prefixIcon: const Icon(Icons.password),
                      ),
                      obscureText: _obscurePassword,
                    ),




                  ],
                ),
                Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),

                    child: ElevatedButton(
                      onPressed: () async {
                        final username = _usernameController.text.trim();
                        final password = _passwordController.text.trim();

                        if (username.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all fields")),
                          );
                          return;
                        }

                        final response = await http.post(
                          Uri.parse("https://<BACKEND-URL>/register"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "username": username,
                            "password": password,
                          }),
                        );


                        if (response.statusCode == 200) {
                          final jsonData = jsonDecode(response.body);
                          final userId = jsonData['user_id'].toString();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User registered! Please login.")),
                          );
                          Navigator.pushNamed(context, '/image_input', arguments: userId);

                        } else {
                          final error = jsonDecode(response.body);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error["detail"] ?? "Something went wrong")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.purple,
                      ),

                      child: const Text(
                        "Sign up",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    )
                ),

                const Center(child: Text("Or")),

                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.purple,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(0, 1), // changes position of shadow
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: loginWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 35.0,
                          width: 30.0,
                          decoration: const BoxDecoration(

                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 18),

                        const Text("Sign Up with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),


                      ],
                    ),
                  ),
                ),
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.purple,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(0, 1), // changes position of shadow
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: loginWithMicrosoft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 35.0,
                          width: 30.0,
                          decoration: const BoxDecoration(

                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 18),

                        const Text("Sign Up with Microsoft",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),


                      ],
                    ),
                  ),
                ),


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("Already have an account?"),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        } ,
                        child: const Text("Login", style: TextStyle(color: Colors.purple),)
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
