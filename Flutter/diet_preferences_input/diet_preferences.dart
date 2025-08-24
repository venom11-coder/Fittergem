import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:login_project/User_Info/user_data.dart';
import 'package:login_project/final_user_info/final_user_info.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_project/User_Info/google_calender_permission.dart';
//import 'package:dotted_border/dotted_border.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class DietPreferences extends StatefulWidget{

  final String firstName;
  final String userId;
  const DietPreferences({
    Key? key,
    required this.firstName,
    required this.userId,
  }) : super(key: key);

  @override
  State<DietPreferences> createState() => _DietPreferencesState();
}

class _DietPreferencesState extends State<DietPreferences> {

  double veganPercent = 0;
  double vegetarianPercent = 0;
  double nonVegetarianPercent = 100;

  final List<String> cuisines = [
    "Indian", "Chinese", "Italian", "Thai", "Mexican", "American",
    "Korean", "Mediterranean", "Japanese", "French", "Greek"
  ];
  List<String> selectedCuisines = [];

  final TextEditingController restrictionController = TextEditingController();

  void updatePercentages(String changedType, double value) {
    double remaining = 100 - value;
    double veg = vegetarianPercent;
    double nonVeg = nonVegetarianPercent;

    if (changedType == "Vegan") {
      if (veg + nonVeg == 0) {
        veg = remaining / 2;
        nonVeg = remaining / 2;
      } else {
        double total = veg + nonVeg;
        veg = (veg / total) * remaining;
        nonVeg = (nonVeg / total) * remaining;
      }
      setState(() {
        veganPercent = value;
        vegetarianPercent = veg;
        nonVegetarianPercent = nonVeg;
      });
    } else if (changedType == "Vegetarian") {
      if (veganPercent + nonVeg == 0) {
        veganPercent = remaining / 2;
        nonVeg = remaining / 2;
      } else {
        double total = veganPercent + nonVeg;
        veganPercent = (veganPercent / total) * remaining;
        nonVeg = (nonVeg / total) * remaining;
      }
      setState(() {
        vegetarianPercent = value;
        nonVegetarianPercent = nonVeg;
      });
    } else if (changedType == "Non-Vegetarian") {
      if (veganPercent + vegetarianPercent == 0) {
        veganPercent = remaining / 2;
        vegetarianPercent = remaining / 2;
      } else {
        double total = veganPercent + vegetarianPercent;
        veganPercent = (veganPercent / total) * remaining;
        vegetarianPercent = (vegetarianPercent / total) * remaining;
      }
      setState(() {
        nonVegetarianPercent = value;
      });
    }
  }

  Future<void> _saveDietPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Save percentages
    await prefs.setDouble('veganPercent', veganPercent);
    await prefs.setDouble('vegetarianPercent', vegetarianPercent);
    await prefs.setDouble('nonVegetarianPercent', nonVegetarianPercent);

    // Save cuisines as JSON string
    await prefs.setString('selectedCuisines', jsonEncode(selectedCuisines));

    // Save restrictions
    await prefs.setString('restrictionText', restrictionController.text);
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text("${value.toStringAsFixed(0)}%"),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          label: "${value.toStringAsFixed(0)}%",
          onChanged: onChanged,
        ),
      ],
    );
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
                    children: [
                      // Step indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          7,
                              (index) =>
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == 5
                                      ? const Color(0xFF341539)
                                      : Colors.grey.shade400,
                                ),
                              ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Purple Header Box
                      // Header Box
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          margin: const EdgeInsets.only(bottom: 20, top: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC7B1E4),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            "Help us personalize your diet and cheat meal plan",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF341539),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ✅ Diet Sliders
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("🍽️ Diet Composition (must sum to 100%)",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildSlider("Vegan", veganPercent, (val) =>
                                updatePercentages("Vegan", val)),
                            _buildSlider(
                                "Vegetarian", vegetarianPercent, (val) =>
                                updatePercentages("Vegetarian", val)),
                            _buildSlider(
                                "Non-Vegetarian", nonVegetarianPercent, (val) =>
                                updatePercentages("Non-Vegetarian", val)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ✅ Cuisines
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("🌍 Favorite Cuisines (Select up to 3)",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: cuisines.map((cuisine) {
                                final isSelected = selectedCuisines.contains(
                                    cuisine);
                                return ChoiceChip(
                                  label: Text(cuisine),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        if (selectedCuisines.length < 3) {
                                          selectedCuisines.add(cuisine);
                                        }
                                      } else {
                                        selectedCuisines.remove(cuisine);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ✅ Restrictions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("🛐 Dietary/Religious Restrictions",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: restrictionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "e.g., No beef, Jain diet, Halal only, Gluten-free...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ✅ Buttons
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
                              if ((veganPercent + vegetarianPercent +
                                  nonVegetarianPercent).round() != 100) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text(
                                      "❌ Diet percentages must add up to 100.")),
                                );
                                return;
                              }
                              if (selectedCuisines.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('❌ Please select your favorite cuisines!'),
                                    duration: Duration(seconds: 5),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;

                              }

                              String cuisines = selectedCuisines.toString();
                             String vegPercent = veganPercent.toString();
                             String nonvegPercent = nonVegetarianPercent.toString();
                             String vegan = veganPercent.toString();

                              _saveDietPreferences();

                              final response_3 =  http.post(Uri.parse("https://<BACKEND-URL>/user-diet-preferences-store"),
                                  headers: {"Content-Type": "application/json"},
                                  body: jsonEncode({
                                    "user_id": widget.userId,
                                    "favorite_cuisines": selectedCuisines.toString(),
                                    "other_restrictions": restrictionController.text,
                                    "diet_percentage": "All values in % vegetarian:$vegPercent, vegan: $vegan, non-vegetarian: $nonvegPercent ",
                                  }));
                              Navigator.push(
                                context,
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
                                ),
                              );

                              // for updating veg, non veg and vegan percentage for next page
                              UserData.vegetarianPercent= vegetarianPercent;
                              UserData.veganPercent= veganPercent;
                              UserData.nonVegPercent= nonVegetarianPercent;

                              // for preferred cuisines
                              UserData.cuisines = selectedCuisines;

                              // for any special restrictions
                              UserData.restrictionText = restrictionController.text;



                              // TODO: Navigate to next screen
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text("Next"),
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
