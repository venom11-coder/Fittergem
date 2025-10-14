import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'dart:convert';
import 'package:Fittergem/User_Info/user_data.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SignupPage extends StatefulWidget {

  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final Random random = Random();
  final bool _obscurePassword = true;
  final TextEditingController _firstnameController =TextEditingController();
  final TextEditingController _lastnameController =TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Show privacy policy after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPasswordPolicy();
    });
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<void> saveemail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  }
  Future<String?> getemail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  // saves the firstname to frontend memory
  Future<void> saveFirstName(String firstName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', firstName);
  }
  Future<String?> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firstName');
  }
  Future<void> saveLastName(String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastName', lastName);
  }

  Future<String?> getLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastName');
  }

  Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _showPasswordPolicy() async {
    bool accepted = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // Must accept or decline
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Password Policy & Disclaimer",
                style: GoogleFonts.bebasNeue(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Fittergem values your privacy. You are solely responsible for creating, maintaining, and protecting your account credentials (including passwords)."
                    "You agree to choose strong passwords and to keep them confidential. We recommend using a password that is at least"
                    " 12 characters long and includes a mix of uppercase and lowercase letters, numbers, and symbols. If you suspect your password has been compromised, "
                    "you must change it immediately and notify us through the support channels. We will assist within the limits of our operational capabilities.\n\n"
                ,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pop(context); // Decline -> go back
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text(
                          "You need to accept the policy to continue.",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.black,
                        duration: const Duration(seconds: 3),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Decline", style: TextStyle(color: Colors.black),),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      accepted = true;
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Accept", style: TextStyle(color: Colors.black),),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    // Optionally, you can store this acceptance in SharedPreferences to not show again
    if (accepted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("policy_accepted", true);
    }
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
        saveUserId(user.uid.toString());
        UserData.userId = user.uid;
      }

      print(fullname);
      print(email);

      // split the fullname to get first name for image input
      List<String> names = fullname?.split(' ') ?? [];

      String firstName = names.isNotEmpty ? names.first : "";
      String lastName = names.length > 1 ? names.sublist(1).join(" ") : "";
      saveFirstName(firstName);
      saveLastName(lastName);
      if(email != null)
        saveemail(email);

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        print(UserData.redirect);
        saveUserId(user.uid.toString());
        UserData.userId= prefs.getString('user_id')!;
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
        "tenant": "b630a16c-d92b-4b29-a6ef-fdbc200c2f37"
      });

      final userCredential = await FirebaseAuth.instance.signInWithProvider(
          provider);

// optional: get user info
      final user = userCredential.user;
      print("✅ Microsoft login: ${user?.email} | UID: ${user?.uid}");
      String? email = user?.email;
      if(email != null){
        saveemail(email);
      }

      final user_microsoft = userCredential.user;
      final userId = user?.uid ?? "";
      final fullName = user?.displayName ?? "";
      final parts = fullName.trim().split(' ');
      final firstName = fullName
          .split(' ')
          .first;
      final lastName = parts.length > 1 ? parts.last : "";
      saveFirstName(firstName);
      saveLastName(lastName);

      UserData.fullname = fullName;
      UserData.email = user?.email;
      if (user_microsoft != null) {
        print("✅ Microsoft login successful: ${user?.email}");

        if (user != null) {
          saveUserId(user.uid.toString());
          UserData.userId = user.uid;
        }
        if(email != null)
          saveemail(email);

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
                      padding: const EdgeInsets.only(top: 20,right:240),

                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.purple, size: 65,),
                        onPressed: () {
                          Navigator.pop(context); // Go back to previous screen
                        },
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
                      controller: _firstnameController,
                      decoration: InputDecoration(
                          hintText: "First Name",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          fillColor: Colors.purple.withOpacity(0.1),
                          filled: true,
                          prefixIcon: const Icon(Icons.email)),
                    ),

                    const SizedBox(height: 20),
                    TextField(
                      controller: _lastnameController,
                      decoration: InputDecoration(
                          hintText: "Last Name",
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
                const SizedBox(height: 20),
                Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),

                    child: ElevatedButton(
                      onPressed: () async {

                        final firstname = _firstnameController.text.trim();
                        final lastname = _lastnameController.text.trim();
                        final username = _usernameController.text.trim();
                        final password = _passwordController.text.trim();




                        if (username.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill all fields")),
                          );
                          return;
                        }


                        saveFirstName(firstname);
                        saveLastName(lastname);

                        saveemail(username);
                        final response = await http.post(
                          Uri.parse("https://userauthenticationlogin-production.up.railway.app/register"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "username": username,
                            "password": password,
                          }),
                        );


                        if (response.statusCode == 200) {
                          final jsonData = jsonDecode(response.body);
                          final userId = jsonData['user_id'].toString();
                          saveUserId(userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User registered! Please login.")),
                          );
                          Navigator.pushNamed(context, '/image_input', arguments: {
                            'userID': userId.toString(),
                            'firstname': firstname.toString()
                          });

                        }
                        else if(response.statusCode == 409) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Username already exists")),
                        );

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
