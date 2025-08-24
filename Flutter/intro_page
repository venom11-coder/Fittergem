import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_project/Homepages/homepage.dart';
import 'dart:async';
import 'dart:io';
import 'package:login_project/Introduction/manual_register.dart';
import 'package:login_project/Introduction/FeatureSlider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login_project/User_Info/user_data.dart';
import 'package:login_project/Introduction/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

PageController _controller = PageController();

class Introdpage1 extends StatefulWidget {
  const Introdpage1({super.key});


  @override
  _Introdpage1State createState() => _Introdpage1State();
}

class _Introdpage1State extends State<Introdpage1> {

  Future<bool> _checkAllInfoGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('all_info_given') ?? false;
  }

  Future<File?> _getSavedImageFile() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImagePath');
    if (path != null) {
      return File(path); // Convert back to File
    }
    return null;
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
  Future<void> _initializeUser() async {
    String? userid_stored = await getStoredUserId();
    String? firstName_stored = await getFirstName();
    bool move_to_homepage = await _checkAllInfoGiven();
    File? image = await _getSavedImageFile();
    if (userid_stored!=null && move_to_homepage && firstName_stored!=null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(
                  firstName: firstName_stored,
                  userId: userid_stored,
                  profileImageUrl: image,
                ),
          ),
        );
      });
    }
  }

    @override
    void initState() {
      super.initState();
      _initializeUser();
    }



  // checks if the all_info_given is true to redirect to the homepage
  // instead of letting the user input the values again



  // stores userid in frontend memory


  // gets userid from frontend memory




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
      saveFirstName(firstName);
      saveLastName(lastName);
      if(email != null)
      saveemail(email);

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
          UserData.userId = user.uid;
          saveUserId(user.uid);// ✅ no ?
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
      if (UserData.redirect == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                firstName: UserData.firstname,
                userId: UserData.userId,
                profileImageUrl: UserData.image,
              ),
            ),
          );
        });

        // Show something while redirecting
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        body: Container(
          color: const Color(0xFF341539),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Spacer(flex: 1),
              // New: Add a Spacer at the very top to push content down dynamically

              Text(
                'Fittergem',
                style: GoogleFonts.bebasNeue(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 52,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              // Small fixed space between title and slogan
              Text(
                'You move, we adapt',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.5,
                ),
              ),

              Spacer(flex: 1),
              // Spacer after slogan to push next content down

              // FeatureSlider section - now uses flex to share space
              Expanded(
                flex: 3, // Increased flex to give it more space
                child: Column(
                  // REMOVED: mainAxisSize: MainAxisSize.min, // THIS WAS THE PROBLEM!
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Vertically centers FeatureSlider within its Expanded space
                  children: [
                    FeatureSlider(),
                    // If FeatureSlider itself needs padding at the bottom, adjust its internal padding
                    // or add a very small SizedBox here if necessary, but avoid large fixed spaces.
                  ],
                ),
              ),

              // Button section - now uses flex to share space
              const SizedBox(height: 85),
              Expanded(
                flex: 4,
                // Increased flex to give buttons more space than FeatureSlider
                child: SingleChildScrollView( // Keep SingleChildScrollView for safety, but aim not to need it
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 60),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    // Reduced vertical padding here
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // Keep this for button column
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignupPage()));
                          },
                          child: const Text('Register Manually'),
                        ),
                        const SizedBox(height: 8),
                        // Reduced spacing between buttons
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: loginWithGoogle,
                          child: const Text('Sign in with Google'),
                        ),
                        const SizedBox(height: 8),
                        // Reduced spacing
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[300],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: loginWithMicrosoft,
                          child: const Text('Sign in with Microsoft'),
                        ),
                        const SizedBox(height: 8),
                        // Small spacer at the end of buttons
                      ],
                    ),
                  ),
                ),
              ),

              // Spacer to push the "Already have an account?" text upwards
              // Spacer(flex: 1), // This spacer will take up remaining space above the last row

              // The "Already have an account?" text and "Login" button outside the box
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                // Adjust this value to control overall bottom spacing
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (
                              context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }



