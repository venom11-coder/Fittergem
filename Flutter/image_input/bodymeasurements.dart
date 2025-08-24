import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:login_project/User_Info/user_data.dart';
import 'package:login_project/User_Info/user_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:login_project/User_Info/user_info_1.dart';
import 'package:login_project/final_user_info/final_user_info.dart';
//import 'package:dotted_border/dotted_border.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;


class bodymeasurements extends StatefulWidget {
  final File image;
  final String warning;
  final String userId;
  final String firstName;

  const bodymeasurements({
    super.key,
    required this.image,
    required this.userId,
    required this.firstName,
    required this.warning,
  });

  @override
  State<bodymeasurements> createState() => _ImageInputPageState();
}


class _ImageInputPageState extends State<bodymeasurements> {
  late double height;
  late double weight;
  late int age;
 late String gender;
  File? _image;
  String? warning;
  bool _isloading = false;

  void _clearimage(){
    setState(() {
      _image=null;
    });
  }
  void redo(){
    setState(() {
      _image=null;
      _isloading= false;

    });
  }

  @override
  void initState() {
    super.initState();
    _image = widget.image;
    warning = widget.warning;
    _submitImage();  // auto call prediction on start
  }
  Future<void> setheight(double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('height', height);
  }

  Future<void> setage(int age) async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('age', age);
  }

  Future<void> setweight(double weight) async{

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weight', weight);
  }

  Future<void>setgender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', gender);
  }
  Future<void> showEditDialog({
    required String fieldName,
    required String currentValue,
    required void Function(String newValue) onSave,
  }) async {
    TextEditingController controller = TextEditingController(text: currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $fieldName"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new $fieldName"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Male"),
              onTap: () {
                setState(() {
                  gender = "male";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Female"),
              onTap: () {
                setState(() {
                  gender = "female";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Prefer not to say"),
              onTap: () {
                setState(() {
                  gender = "prefer not to say";
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }





  // Accepts original picked image
  Future<File> resizeImage(File originalImage) async {
    final rawImage = img.decodeImage(await originalImage.readAsBytes());

    if (rawImage == null) {
      throw Exception("❌ Unable to decode image. Unsupported or corrupted.");
    }

    // Resize to max 1000px side
    final resized = img.copyResize(rawImage, width: 1000);

    // Compress to JPEG with 80% quality
    final compressedBytes = img.encodeJpg(resized, quality: 80);

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final resizedFile = File('${tempDir.path}/resized_image.jpg');
    await resizedFile.writeAsBytes(compressedBytes);

    return resizedFile;
  }

  Future<void> _submitImage() async {
    if (_image == null || _isloading) {
      return; // Check if image is null or already loading
    }

    setState(() {
      _isloading = true; // Set loading state to true AT THE START
    });

    //print("📸 Image path: ${_image!.path}");
    //print("📸 File exists: ${await File(_image!.path).exists()}");
    //print("📸 File size: ${await File(_image!.path).length()}");


    final url = Uri.parse("https://<BACKEND-URL>/predict");
    // Your backend endpoint

    var request = http.MultipartRequest("post", url);

    request.fields['user_id'] = widget.userId; // ✅ Important

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _image!.path,
    ));
   request.fields['warning'] = warning ?? "";

    var response = await request.send(); // Send the request

    var responseBackend = await response.stream
        .bytesToString(); // Get the response body

    if (responseBackend.trim().isEmpty) {
      throw Exception("Empty response from backend.");
    }





    // gets jsonfiy details from backend
    final Map<String, dynamic> jsonResponse = jsonDecode(responseBackend);

    setState(() {


    height = jsonResponse["height_cm"];
     gender= jsonResponse["gender"];
     age = jsonResponse["age"];
     weight = jsonResponse["weight"];
    _isloading = false;

    print("📦 Full response: $jsonResponse");

    if (jsonResponse["height_cm"] == null) {
      print("❌ height_cm is null");
    }
    if (jsonResponse["weight"] == null) {
      print("❌ weight is null");
    }
    if (jsonResponse["age"] == null) {
      print("❌ age is null");
    }
    if (jsonResponse["gender"] == null) {
      print("❌ gender is null");
    }
    });

    //debugPrint("🔥 Backend status: $status");
    //debugPrint("🔥 Backend reason: $reason");
    //debugPrint("🔥 Full backend response: $jsonResponse");



    }




  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage==null)
      return;

    if (pickedImage != null) {
      // Resize the image before setting and submitting
      File originalFile = File(pickedImage.path);
      //final ext = pickedImage.path.toLowerCase().split('.').last;

      // if extension is heic or heif

      //final resizedFile = await resizeImage(originalFile);
      if (!await originalFile.exists() || await originalFile.length() == 0) {
        throw Exception("❌ Resized image is empty or corrupted.");
      }

      setState(() {
        _image = originalFile;
      });


      // Start image verification from backend
      await _submitImage();



    }
  }



  @override
  Widget build(BuildContext context) {
    final String userId = widget.userId;
    final String firstName = widget.firstName;
    final String warning = widget.warning;

    if (_isloading || height == null || weight == null || age == null || gender == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


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
                height: MediaQuery.of(context).size.height * 0.75,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E4E2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),



                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),



                    child: Center(
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
                                  color: index == 0 ? Color(0xFF341539) : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),


                          // --- Instruction Text Container (FIXED SYNTAX HERE) ---
                          Padding(
                            padding: const EdgeInsets.only(top: 30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Height(cm)",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12), // spacing between text and box




                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$height",
                                        style: GoogleFonts.poppins(fontSize: 15),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () {
                                       showEditDialog(
                                       fieldName: "Height",
                                       currentValue: "$height",
                                       onSave: (val) {
                                       setState(() {
                                       height = double.tryParse(val) ?? height!;
                                                });
                                             },
                                           );
                                         },


                                      )
                                    ],
                                  ),
                                ),
                                Text(
                                  "Weight(kgs)",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12), // spacing between text and box
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$weight",
                                        style: GoogleFonts.poppins(fontSize: 15),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        onPressed: () {
                                          showEditDialog(
                                            fieldName: "Weight",
                                            currentValue: "$weight",
                                            onSave: (val) {
                                              setState(() {
                                                weight = double.tryParse(val) ?? weight!;
                                              });
                                            },
                                          );
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                Text(
                                  "Gender",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12), // spacing between text and box
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$gender",
                                        style: GoogleFonts.poppins(fontSize: 15),
                                      ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () {
                                      _showGenderPicker();
                                    },
                                  )

                                    ],
                                  ),
                                ),
                                Text(
                                  "Age",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12), // spacing between text and box
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$age",
                                        style: GoogleFonts.poppins(fontSize: 15),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        onPressed: () {
                                          showEditDialog(
                                            fieldName: "Age",
                                            currentValue: "$age",
                                            onSave: (val) {
                                              setState(() {
                                                age = int.tryParse(val) ?? age!;
                                              });
                                            },
                                          );
                                        },

                                      )
                                    ],
                                  ),
                                ),
                              ],
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
                      onPressed: () {

                        //stores in memory of flutter

                          setage(age);
                          setgender(gender);
                          setheight(height);
                          setweight(weight);

                        // your next step logic
                        // changes the User data class fields
                        UserData.height = height;
                        UserData.weight = weight;
                        UserData.gender = gender;
                        UserData.age = age;


                        print(UserData.FinalPage);

                        String? name = UserData.fullname;
                        print(name);


                        final response_3 = http.post(Uri.parse(
                            "https://<BACKEND-URL>/body-measurements-store"),
                            headers: {"Content-Type": "application/json"},
                            body: jsonEncode({
                              "user_id": widget.userId,
                              "age": age,
                              "weight": weight,
                              "height": height,
                              "gender": gender,
                              "full_name": name,
                            }));
                        print("sent to AI");


                        if (UserData.FinalPage == false) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                  milliseconds: 500),
                              pageBuilder: (context, animation,
                                  secondaryAnimation) =>
                                  user_info_1(
                                    firstName: firstName,
                                    userId: userId,
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
                        // if the user came to edit info then takes to final page with edited info
                        if (UserData.FinalPage == true) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                  milliseconds: 500),
                              pageBuilder: (context, animation,
                                  secondaryAnimation) =>
                                  FinalUserInfo(
                                    firstName: firstName,
                                    userId: userId,
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
          )
                  ]
       )
      );

  }
}
