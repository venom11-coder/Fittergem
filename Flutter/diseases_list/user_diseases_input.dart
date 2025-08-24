import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:login_project/User_Info/user_data.dart';
import 'package:login_project/User_Info/user_health_info.dart';
import 'dart:io';
import 'package:login_project/User_Info/user_health_info.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_project/User_Info/user_health_info.dart';
//import 'package:dotted_border/dotted_border.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import '../final_user_info/final_user_info.dart';

class user_info_1 extends StatefulWidget {

  final String firstName;
  final String userId;

  const user_info_1({
    Key? key,
    required this.firstName,
    required this.userId,
  }) : super(key: key);
@override
  State<user_info_1> createState() => _UserInfo1State();

}
class _UserInfo1State extends State<user_info_1> {

  String? condition;
  bool _hasdisease = false;
  String? condition_type;

  Future<void> setDiseases(String Diseases) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('diseases', Diseases );
  }

  final List<String> diseases = [
    "Diabetes",
    "Heart Disease",
    "Asthma",
    "Arthritis",
    "Multiple Sclerosis",
    "Thyroid Disorder",
    "Anxiety / Depression",
    "PCOS"
  ];

  late Map<String, bool> selectedConditions;
  late Map<String, String> severityLevels;

  @override
  void initState() {
    super.initState();

    selectedConditions = {
      for (var disease in diseases) disease: false,
    };

    severityLevels = {
      for (var disease in diseases) disease: "",
    };
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
                              color: index == 1 ? Color(0xFF341539) : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(height: 20),

                      // ✅ Purple rectangle with the question
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          margin: const EdgeInsets.only(bottom: 25, top: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7B1E4),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            "Do you suffer any of the diseases mentioned? (Optional)",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF341539),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      ...diseases.map((disease) {
                        final selected = selectedConditions[disease]!;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: selected ? Colors.deepPurple.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.deepPurple, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedConditions[disease] = !selected;
                                    if (!selected) severityLevels[disease] = "";
                                  });
                                },

                                child: Row(
                                  children: [
                                    Icon(
                                      selected ? Icons.check_circle : Icons.circle_outlined,
                                      color: Colors.deepPurple,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      disease,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Wrap(
                                    spacing: 10,
                                    children: ["Mild", "Moderate", "Severe"].map((level) {
                                      final selectedLevel = severityLevels[disease];
                                      return ChoiceChip(
                                        label: Text(level),
                                        selected: selectedLevel == level,
                                        onSelected: (selected) {
                                          setState(() {
                                            severityLevels[disease] = level;
                                          });
                                        },
                                        selectedColor: Colors.deepPurple,
                                        labelStyle: TextStyle(
                                          color: selectedLevel == level ? Colors.white : Colors.black,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                            ],
                          ),
                        );
                      }).toList(),

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
    onPressed: () async {
    // collect selected + with severity
    final picked = selectedConditions.entries
        .where((e) => e.value)
        .map((e) => {
    "name": e.key,
    "severity": (severityLevels[e.key] ?? "").trim()
    })
        .toList();

    // if any selected but missing severity, prompt user (optional)
    final missing = picked.any((m) => (m["severity"] as String).isEmpty);
    if (missing) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Pick a severity for each selected condition.")),
    );
    return;
    }

    // only send if there’s something
    if (picked.isNotEmpty) {
    // pack everything into a single string for `message`
      final messageString = "HEALTH_CONDITIONS: " +
          picked.map((m) => "${m['name']}(${m['severity']})").join("; ");
      setDiseases(messageString);


      try {
    final res = await http.post(
    Uri.parse("https://<BACKEND-URL>/user-diseases-store"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
    "user_id": widget.userId,     // string
    "diseases": messageString,     // stringified JSON
    }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
    debugPrint("Save conditions failed: ${res.statusCode} ${res.body}");
    }
    } catch (e) {
    debugPrint("Save conditions error: $e");
    }
    }

    // continue

    if (UserData.FinalPage== false) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              UserHealthInfo(
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
        ),
      );
    }
    if (UserData.FinalPage== true) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              FinalUserInfo(
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
        ),
      );
    }
    },

    style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF341539),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              ),
                              icon: const Icon(Icons.arrow_forward, color: Colors.white),
                              label: const Text("Next", style: TextStyle(color: Colors.white)),
                            )


                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}


