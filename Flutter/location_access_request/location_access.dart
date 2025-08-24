import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:login_project/User_Info/user_data.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_project/Introduction/Introdpage1.dart';
import 'package:login_project/User_Info/user_health_info.dart';
import 'package:login_project/final_user_info/final_user_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_project/User_Info/google_calender_permission.dart';
//import 'package:dotted_border/dotted_border.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationAccess extends StatefulWidget {

  final String firstName;
  final String userId;
  const LocationAccess({
    Key? key,
    required this.userId,
    required this.firstName,
  }) : super(key: key);
  @override
  State<LocationAccess> createState() => _LocationAccessState();

}

class  _LocationAccessState extends State<LocationAccess> {
  int currentpageIndex = 1;
  int totalpages = 7;

  Future<void> set_location_accessed() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_data_accessed', true);
  }

  Future<void> set_location_not_accessed() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_data_accessed', false);
  }



  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;



    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("❌ Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("❌ Location permissions are permanently denied.");
      return;
    }

    // ✅ Location fetched
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print("📍 Latitude: ${position.latitude}, Longitude: ${position.longitude}");

    String timezone = '';



    // ✅ Send to Flask
    final response = await http.post(
      Uri.parse("https://<BACKEND-URL>/timezone"),  // replace with real backend
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "latitude": position.latitude,
        "longitude": position.longitude,
      }),
    );

    if (response.statusCode == 200) {
      final message = jsonDecode(response.body);
      timezone = message['timeZoneId'].toString();
      print("🕓 Your timezone: $timezone");
    }


    await http.post(
      Uri.parse("https://<BACKEND-URL>/calendar-token-store"),
      body: jsonEncode({
        "timezone": timezone,
      }),
      headers: {"Content-Type": "application/json"},
    );


    final response_2 = await http.post(
      Uri.parse("https://<BACKEND-URL>/restraunts"),  // replace with real backend
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "latitude": position.latitude,
        "longitude": position.longitude,
      }),
    );
    String restaurants = '';
    if (response_2.statusCode == 200) {
      final foodData = jsonDecode(response_2.body);
      restaurants = foodData['restaurants'].toString();
      print("🕓 Your nearby Restaraunts: $restaurants");
    }
    final userId = widget.userId;
    final response_3 = await http.post(Uri.parse("https://<BACKEND-URL>/user-location-data-store"),
      headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "user_id": widget.userId,
      "timezone": timezone,
      "restaurants": restaurants,
    }));

    if(UserData.FinalPage==false) {
      Navigator.push(context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              GoogleCalenderPermission(
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
    if (UserData.FinalPage==true) {
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
                              color: index == 3
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



                      if(UserData.Locationaccessed==false)...[
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
                                  Icon(Icons.my_location, color: Colors.deepPurple),
                                  const SizedBox(width: 20, height: 50,),
                                  const Text(
                                    "Connect Your Location",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Get cheat meal suggestions based on the food places around and based on your diet preferences!",
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await getLocation();
                                    set_location_accessed();
                                    // Launch backend in browser
                                    UserData.Locationaccessed = true;
                                    // Wait for login to complete
                                    // After successful login, navigate or show confirmation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("✅ Location accessed successfully!")),
                                    );
                                    // Optional: move to next onboarding screen
                                    if(UserData.FinalPage==false) {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          transitionDuration: const Duration(
                                              milliseconds: 500),
                                          pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                              GoogleCalenderPermission(
                                                firstName: widget.firstName,
                                                userId: widget.userId,
                                              ),
                                          transitionsBuilder: (context,
                                              animation, secondaryAnimation,
                                              child) {
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
                                        ),
                                      );
                                    }
                                    if(UserData.FinalPage==true) {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          transitionDuration: const Duration(
                                              milliseconds: 500),
                                          pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                              FinalUserInfo(
                                                firstName: widget.firstName,
                                                userId: widget.userId,
                                              ),
                                          transitionsBuilder: (context,
                                              animation, secondaryAnimation,
                                              child) {
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
                                        ),
                                      );
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
                      if(UserData.Locationaccessed==true)...[
                        const SizedBox(height: 24,),
                        GestureDetector(
                          onTap: () {
                            // trigger calendar connect logic
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 0),
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
                                    Icon(Icons.my_location, color: Colors.deepPurple),
                                    const SizedBox(width: 20, height: 50,),
                                    const Text(
                                      "Connect Your Location",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Your location has been accessed and will be used to give you the best cheat meals from your nearby food places!",
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      UserData.Locationaccessed= false;
                                      final response_3 = await http.post(Uri.parse("https://<BACKEND-URL>/user-location-data-remove"),
                                          headers: {"Content-Type": "application/json"},
                                          body: jsonEncode({
                                            "user_id": widget.userId,
                                          }));
                                      // Launch backend in browser

                                      // Wait for login to complete
                                      // After successful login, navigate or show confirmation
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("✅ Location data removed successfully!")),
                                      );
                                      // Optional: move to next onboarding screen
                                      if(UserData.FinalPage==false) {
                                        UserData.Locationaccessed= false;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LocationAccess(
                                              firstName: widget.firstName,
                                              userId: widget.userId,
                                            ),
                                          ),
                                        );
                                      }
                                      if(UserData.FinalPage==true) {
                                        UserData.Locationaccessed= false;
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

                      const SizedBox(height: 30),

                      // Back & Skip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 500),
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      UserHealthInfo(
                                        firstName: widget.firstName,
                                        userId: widget.userId,
                                      ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(-1.0, 0.0);
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
                              print(UserData.FinalPage);
                               UserData.Locationaccessed = false;
                               set_location_not_accessed();
                              // 👉 Go to next page (optional or required)
                              //Navigator.push(context, route)
                               if(UserData.FinalPage==false) {
                                 Navigator.push(
                                   context,
                                   PageRouteBuilder(
                                     transitionDuration: const Duration(
                                         milliseconds: 500),
                                     pageBuilder: (context, animation,
                                         secondaryAnimation) =>
                                         GoogleCalenderPermission(
                                           firstName: widget.firstName,
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
                                   ),
                                 );
                               }
                               if(UserData.FinalPage==true) {
                                 Navigator.push(
                                   context,
                                   PageRouteBuilder(
                                     transitionDuration: const Duration(
                                         milliseconds: 500),
                                     pageBuilder: (context, animation,
                                         secondaryAnimation) =>
                                         FinalUserInfo(
                                           firstName: widget.firstName,
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
                                   ),
                                 );
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
