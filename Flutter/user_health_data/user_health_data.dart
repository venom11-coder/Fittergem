import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:login_project/final_user_info/final_user_info.dart';
import 'package:url_launcher/url_launcher_string.dart'; // OR if using `LaunchMode`
import 'package:url_launcher/url_launcher.dart' show launchUrl, canLaunchUrl, LaunchMode;
import 'package:login_project/User_Info/user_data.dart';
import 'package:login_project/User_Info/location_access.dart';
import 'package:login_project/User_Info/user_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_project/User_Info/google_calender_permission.dart';
//import 'package:dotted_border/dotted_border.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';




class UserHealthInfo extends StatefulWidget {

  final String firstName;
  final String userId;

  const UserHealthInfo({
    Key? key,
    required this.firstName,
    required this.userId,
  }) : super(key: key);
  @override
  State<UserHealthInfo> createState() => _UserHealthInfoState();

}




class _UserHealthInfoState extends State<UserHealthInfo> {

  void _showInstallHealthConnectSnackbar() {
    final Uri uri = Uri.parse('https://play.google.com/store/search?q=Health%20Connect&c=apps');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🚫 Health Connect not installed. Please install it to continue."),
        action: SnackBarAction(
          label: "Install",
          textColor: Colors.blueAccent,
          onPressed: () async {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  Future<void> set_health_data_accessed() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('healthdatacced', true); // or false
  }
  Future<void> set_health_data_not_accessed() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('healthdatacced', false);
  }
  Future<void> set_health_data(
  // for sleep
  String? selectedSleepOption,
  // for workouts
  String? selectedworkoutdays,
  // for motivation slider
  double _motivationLevel) async {
    set_health_data_not_accessed();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if(selectedSleepOption !=null)
    await prefs.setString('selectedSleepOption', selectedSleepOption);
    if(selectedworkoutdays !=null)
      await prefs.setString('selectedworkoutdays', selectedworkoutdays);
    await prefs.setDouble('motivationLevel', _motivationLevel);
  }


  final Health health = Health();

  int steps = 0;
  double calories = 0;
  double sleepHours = 0;
  double heartrate = 0;
  double excercisetime = 0;

  final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
    HealthDataType.EXERCISE_TIME,
  ];

  Future<bool> fetchData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    Map<Permission, PermissionStatus> statuses = await [
      Permission.activityRecognition,
      Permission.sensors,
    ].request();

    //final status = await health.getHealthConnectSdkStatus();

    //print("status:$status");


    // 🛑 If not granted, return early
    if (statuses[Permission.activityRecognition] != PermissionStatus.granted ||
        statuses[Permission.sensors] != PermissionStatus.granted) {
      print("❌ Required permissions not granted");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return false ;
    }

    bool requested = false;
    try {
      requested = await health.requestAuthorization(types);
      if (!requested) {
        _showInstallHealthConnectSnackbar();
        return false;
      }
    } catch (e) {
      print("❌ Health Connect request failed: $e");
      _showInstallHealthConnectSnackbar();
      return false;
    }

    if (requested) {
      try {
        List<HealthDataPoint> data =
        await health.getHealthDataFromTypes(
          startTime: midnight,
          endTime: now,
          types: types,
        );

        data = health.removeDuplicates(data);

        int totalSteps = 0;
        double totalCalories = 0;
        double totalSleepSeconds = 0;
        double totalHR = 0;
        int hrCount = 0;
        double totalExercise = 0;

        for (var point in data) {
          if (point.type == HealthDataType.HEART_RATE) {
            totalHR += (point.value as num).toDouble();
            hrCount++;
          } else if (point.type == HealthDataType.EXERCISE_TIME) {
            totalExercise += (point.value as num).toDouble();
          }
        }

        for (var point in data) {
          if (point.type == HealthDataType.STEPS) {
            totalSteps += (point.value as num).toInt();
          } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
            totalCalories += (point.value as num).toDouble();
          } else if (point.type == HealthDataType.SLEEP_ASLEEP) {
            totalSleepSeconds +=
                point.dateTo.difference(point.dateFrom).inSeconds.toDouble();
          }
        }

        setState(() {
          steps = totalSteps;
          calories = totalCalories;
          sleepHours = totalSleepSeconds / 3600;
          heartrate = hrCount > 0 ? totalHR / hrCount : 0;
          excercisetime = totalExercise;
        });
       String  message = "Here is the health data from Health Connect"
           "Total Steps: $totalSteps"
           "calories burned: $totalCalories"
           "sleep hours: $sleepHours"
           "heart Rate: $heartrate"
           "execercise time: $excercisetime"
        "it could be possible that any of these values is 0, do not assume that the user does not literally do it.";
        set_health_data_accessed();
        sendtoAIAgent_Health_Connect(message);
        return true;
      } catch (e) {
        print("Error fetching health data: $e");
        return false;
      }
    } else {
      print("Authorization not granted");
      return false;
    }
  }

  String _selectedOption = '';
  // for sleep
  String? selectedSleepOption="";
  // for workouts
  String? selectedworkoutdays;
  // for motivation slider
  double _motivationLevel = 5.0;

  Future <void> sendtoAIAgent_Health_Connect(String message) async{

    final url = Uri.parse("https://<BACKEND-URL>/user-health-data-store");
    try {
     final response = await http.post(url, headers: {"Content-Type": "application/json"},
       body: jsonEncode(
         {
           "user_id": widget.userId,
           "health_info": message,
         }
       ),);
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ An unexpected error while reading your health data!'),
          duration: Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

  }
  Future<void> Delete_Health_Data() async{
    UserData.healthdataaccess==false;
    final url = Uri.parse("https://<BACKEND-URL>/user-health-data-store");
    try {
      final response = await http.post(url, headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {
              "user_id": widget.userId,

            }
        ),);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Your Health Data has been successfully removed!'),
            duration: Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          )
      );
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ An unexpected error while removing your health data inputted!'),
          duration: Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

  }
  Future <void> sendtoAIAgent_Health_Manually(String message) async{

    UserData.healthdataaccess==true;

    final url = Uri.parse("https://<BACKEND-URL>/user-health-data-store");
    try {
      final response = await http.post(url, headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {
              "user_id": widget.userId,
              "health_info": message,
            }
        ),);
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ An unexpected error while reading your health data inputted!'),
          duration: Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

  }


  Widget ManualHealthInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How many hours a day do you usually sleep?",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ["1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "more than 7"].map((option) {
              return ChoiceChip(
                label: Text(option),
                selected: selectedSleepOption == option,
                onSelected: (selected) {
                  setState(() {
                    selectedSleepOption = selected ? option : null;
                  });
                },
              );
            }).toList(),
          ),


    const SizedBox(height: 28),
    Column(
    crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "How motivated are you to work out?",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Slider(
          value: _motivationLevel,
          min: 1,
          max: 10,
          divisions: 9,
          label: _motivationLevel.round().toString(),
          onChanged: (value) {
            setState(() {
              _motivationLevel = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("😴", style: TextStyle(fontSize: 20)),
            Text("💪", style: TextStyle(fontSize: 20)),
          ],
        )
      ],
    ),
          const SizedBox(height: 27),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "How many days a week do you usually workout?",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: ["0-1","1-2", "2-3", "3-4", "4-5", "5-6", "6-7", "7"].map((option) {
                  return ChoiceChip(
                    label: Text(option),
                    selected:  selectedworkoutdays == option,
                    onSelected: (selected) {
                      setState(() {
                        selectedworkoutdays = selected ? option : null;
                      });
                    },
                  );
                }).toList(),
              ),

            ],
          )

    ],
      ),
    );
  }

  Widget HealthDataAccess(){


   return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 30.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF341539),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Connect your Health Connect/ Apple Health to auto-fill your:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Text("💤  ", style: TextStyle(fontSize: 18)),
              Text("Sleep hours",
                  style:
                  TextStyle(fontSize: 16, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: const [
              Text("🦶", style: TextStyle(fontSize: 18)),
              Text(
                "Steps & workout frequency",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),


          const SizedBox(height: 6),
          Row(
            children: const [
              Text("🔥  ", style: TextStyle(fontSize: 18)),
              Text("Motivation level",
                  style:
                  TextStyle(fontSize: 16, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "You'll skip 3 questions, and get smarter AI coaching instantly!",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          if(UserData.healthdataaccess==false)...[
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () async {
                  bool success = await fetchData();
                  if (success) {
                    if (UserData.FinalPage == false) {
                      Navigator.push(context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
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
                        ),);
                    }
                    if (UserData.FinalPage == true) {
                      Navigator.push(context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
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
                        ),);
                    }
                  } else {
                    print(
                        "❌ Staying on same page due to failure or missing Health Connect");
                  }
                },

                style: TextButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Connect",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
          if(UserData.healthdataaccess==true)...[
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () async {
                  bool success = await fetchData();
                  if (success) {
                    if (UserData.FinalPage == false) {
                      Navigator.push(context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
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
                        ),);
                    }
                    if (UserData.FinalPage == true) {
                      Navigator.push(context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
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
                        ),);
                    }
                  } else {
                    print(
                        "❌ Staying on same page due to failure or missing Health Connect");
                  }
                },

                style: TextButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Connect",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ]


        ],

      ),
   );


  }
  @override
  Widget build(BuildContext context) {
    final String firstName = widget
        .firstName; // Use the widget variable directly

    int currentpageIndex = 1;
    int totalpages = 7;




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

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.75,
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
               mainAxisSize: MainAxisSize.min,
              children: [
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
            color: index == 2
           ? const Color(0xFF341539)
            : Colors.grey.shade400,
            ),
           ),
         ),
        ),

    const SizedBox(height: 20),

      Center(
       child: Column(
        children: [
    // Purple header box
        Container(
         padding:
         const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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


              const SizedBox(height: 20),

              // Tile 1 - Give Access to Health Data
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedOption = 'health';
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedOption == 'health' ? Colors.deepPurple.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _selectedOption == 'health' ? Icons.check_circle : Icons.circle_outlined,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Give Access to Health Data (Recommended)",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedOption == 'health') ...[
                        const SizedBox(height: 12),
                        HealthDataAccess(),
                      ]
                    ],
                  ),


                ),
              ),

              // Tile 2 - Enter Manually
          // Tile 2 - Enter Manually
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedOption = 'manual';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedOption == 'manual' ? Colors.deepPurple.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepPurple, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedOption == 'manual'
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Enter Info Manually",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_selectedOption == 'manual') ...[
                    const SizedBox(height: 12),
                    ManualHealthInput(),
                  ],
                ],
              ),
            ),
          ),


          Padding(
            padding: const EdgeInsets.only(top: 35.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF341539),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text("Back", style: TextStyle(color: Colors.white)),
                ),


                ElevatedButton.icon(
                  onPressed: ()  {
                    if (selectedSleepOption== ""|| _motivationLevel < 1 || selectedworkoutdays==""){
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Please fill in all the options!'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    UserData.sleephours = selectedSleepOption;
                    UserData.motivationLevel =_motivationLevel;
                    UserData.workoutFrequency = selectedworkoutdays;
                    String  message = "Here is the health data of the user which we got from what the user inputted about himself\n "
                                       "total sleep hours: $selectedSleepOption\n "
                                        "motivation level: $_motivationLevel out of 10 "
                                        "workout Frequency: $selectedworkoutdays per week\n ";
                    set_health_data( selectedSleepOption, selectedworkoutdays, _motivationLevel);
                    sendtoAIAgent_Health_Manually(message);
                    // your next step logic
                    if (UserData.FinalPage==true) {
                      Navigator.push(context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder: (context, animation, secondaryAnimation) => FinalUserInfo(
                            firstName: firstName,
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
                 if (UserData.FinalPage==false) {
                   Navigator.push(context,
                     PageRouteBuilder(
                       transitionDuration: const Duration(milliseconds: 500),
                       pageBuilder: (context, animation, secondaryAnimation) =>
                           LocationAccess(
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
                 }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF341539),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text("Next", style: TextStyle(color: Colors.white)),
                ),

          ]
          ),
          )
              ],
            ),
          ),
        ],
      ),
    ),
    ),
    ),
    ),
    ]
    ),

    );
  }
}
