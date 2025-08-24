import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:login_project/final_user_info/final_user_info.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_project/User_Info/user_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:dotted_border/dotted_border.dart';
import 'package:login_project/User_Info/diet_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class GoogleCalenderPermission extends StatefulWidget {

  final String firstName;
  final String userId;
  const GoogleCalenderPermission({
  Key? key,
  required this.firstName,
    required this.userId,
}) : super(key: key);
  @override
  State<GoogleCalenderPermission> createState() => _RequestCalenderAccess();

}

class _RequestCalenderAccess extends State<GoogleCalenderPermission> {
  int currentpageIndex = 1;
  int totalpages = 7;

  Future<void> set_calendar_accessed() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_data_accessed', true);
  }

  Future<void> set_calendar_not_accessed() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_data_accessed', false);
  }


  // FIX THIS PAGE!!!!
  Future<void> launchGoogleCalendarAuth() async {
    UserData.calenderaccess = true;
    String userId = widget.userId;
    final url = Uri.parse(
        "https://<BACKEND-URL>/calendar-access?user_id=$userId"
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    set_calendar_accessed();

  }




  @override
  Widget build(BuildContext context) {
    final String firstName = widget.firstName;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFF341539)),

          Positioned(
            top: 90,
            left: 80,
            right: 20,


            child: Text(
              "Welcome $firstName,",
              style: GoogleFonts.bebasNeue(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 45,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Main Body
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE5E4E2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          7,
                              (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == 4
                                  ? const Color(0xFF341539)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Purple Header Box
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          margin: const EdgeInsets.only(bottom: 20, top: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7B1E4),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            "Help us personalize your workout, diet and cheat meal plan",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF341539),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if(UserData.calenderaccess==true)...[

                        // Google Calendar Tile
                        const SizedBox(height: 24,),
                        GestureDetector(
                          onTap: () {
                            // trigger calendar connect logic
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.deepPurple, width: 1.5, ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month, color: Colors.deepPurple),
                                    const SizedBox(width: 20, height: 50,),
                                    const Text(
                                      "Connect Google Calendar",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Your workout plan will be customised based on your availability. You can add or remove events from your Calendar using AI! ",
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                     // Launch backend in browser
                                      // Wait for login to complete
                                      UserData.calenderaccess== false;
                                      final response_2 = await http.post(
                                        Uri.parse("https://<BACKEND-URL>/user-calendar-data-remove"),  // replace with real backend
                                        headers: {"Content-Type": "application/json"},
                                        body: jsonEncode({
                                          "user_id": widget.userId,
                                        }),
                                      );
                                      // After successful login, navigate or show confirmation
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("✅ Calendar access removed successfully!")),
                                      );
                                      // Optional: move to next onboarding screen
                                      if(UserData.FinalPage==false) {
                                        UserData.calenderaccess=false;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GoogleCalenderPermission(
                                              firstName: widget.firstName,
                                              userId: widget.userId,
                                            ),
                                          ),
                                        );
                                      }
                                      if(UserData.FinalPage==true) {
                                        UserData.calenderaccess=false;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FinalUserInfo(
                                              firstName: widget.firstName,
                                              userId: widget.userId,
                                            ),
                                          ),
                                        );
                                      }


                                    },
                                    icon: const Icon(Icons.link),
                                    label: const Text("Disconnect"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if(UserData.calenderaccess==false)...[

                      // Google Calendar Tile
                      const SizedBox(height: 24,),
                      GestureDetector(
                        onTap: () {
                          // trigger calendar connect logic
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.deepPurple, width: 1.5, ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month, color: Colors.deepPurple),
                                  const SizedBox(width: 20, height: 50,),
                                  const Text(
                                    "Connect Google Calendar",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Get reminders, optimize workouts, and block off focus time automatically.",
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await launchGoogleCalendarAuth(); // Launch backend in browser
                                   // Wait for login to complete
                                    // After successful login, navigate or show confirmation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("✅ Calendar connected successfully!")),
                                    );
                                    // Optional: move to next onboarding screen
                                    if(UserData.FinalPage==false) {
    Navigator.push(context,
    PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) =>
    DietPreferences(
    firstName: widget.firstName,
    userId: widget.userId,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.ease;

    final tween =
    Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
    position: animation.drive(tween),
    child: child,
    );
    },
    ),);
    }
                                    if(UserData.FinalPage==true) {
                                      Navigator.push(context,
                                        PageRouteBuilder(
                                          transitionDuration: const Duration(milliseconds: 500),
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              FinalUserInfo(
                                                firstName: widget.firstName,
                                                userId: widget.userId,
                                              ),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.ease;

                                            final tween =
                                            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                            return SlideTransition(
                                              position: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                        ),);
                                    }


                                  },
                                  icon: const Icon(Icons.link),
                                  label: const Text("Connect Now"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                     ],
                      const SizedBox(height: 30),

                      // Back & Skip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("Back"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF341539),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              set_calendar_not_accessed();
                              UserData.calenderaccess= false;
                              if(UserData.FinalPage==false) {
                                Navigator.push(context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(
                                        milliseconds: 500),
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                        DietPreferences(
                                          firstName: firstName,
                                          userId: widget.userId,
                                        ),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.ease;

                                      final tween =
                                      Tween(begin: begin, end: end).chain(
                                          CurveTween(curve: curve));

                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),);
                                // 👉 Go to next page (optional or required)
                                //Navigator.push(context, route)
                              }
                              if(UserData.FinalPage==true) {
                                Navigator.push(context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(
                                        milliseconds: 500),
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                        FinalUserInfo(
                                          firstName: firstName,
                                          userId: widget.userId,
                                        ),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.ease;

                                      final tween =
                                      Tween(begin: begin, end: end).chain(
                                          CurveTween(curve: curve));

                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),);
                                // 👉 Go to next page (optional or required)
                                //Navigator.push(context, route)
                              }
                            },
                            
                            icon: const Icon(Icons.skip_next),
                            label: const Text("Skip"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF341539),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

 }
