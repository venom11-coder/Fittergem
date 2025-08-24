import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:login_project/User_Info/user_data.dart';
import 'dart:convert';
import 'package:login_project/User_Info/user_health_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:login_project/image_input/bodymeasurements.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Introduction/Introdpage1.dart';


class ImageInputPage extends StatefulWidget {
  const ImageInputPage({super.key});

  @override
  State<ImageInputPage> createState() => _ImageInputPageState();
}

class _ImageInputPageState extends State<ImageInputPage> {
 late String userId;
  late String firstName;
  File? _image;
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
    saveProfileImage(resizedFile);



    return resizedFile;
  }

 Future<void> saveProfileImage(File imageFile) async {
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('profileImagePath', imageFile.path);

 }


  Future<void> _submitImage(File imageFile) async {
   // print("🔥 _submitImage called");

    _isloading = false;
    if ( _isloading) {
     // print("could not load image");
      return; // Check if image is null or already loading
    }

    setState(() {
      _isloading = true; // Set loading state to true AT THE START
    });

    //print("📸 Image path: ${_image!.path}");
    //print("📸 File exists: ${await File(_image!.path).exists()}");
    //print("📸 File size: ${await File(_image!.path).length()}");


    final url = Uri.parse("https://<BACKEND-URL>/Verification");
    // Your backend endpoint

    var request = http.MultipartRequest("post", url);


    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
    ));
   // print("🚀 Sending request to: $url");
    var response = await request.send(); // Send the request

    var responseBackend = await response.stream
        .bytesToString(); // Get the response body

    if (responseBackend.trim().isEmpty) {
      throw Exception("Empty response from backend.");
    }


    // gets jsonfiy details from backend
    final Map<String, dynamic> jsonResponse = jsonDecode(responseBackend);
    final status = jsonResponse["status"];
    final reason = jsonResponse["reason"];
    final retry = jsonResponse["retry"];

    //debugPrint("🔥 Backend status: $status");
    //debugPrint("🔥 Backend reason: $reason");
    //debugPrint("🔥 Full backend response: $jsonResponse");

    if (status == "success") {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle,
              color: Colors.greenAccent,),
            const SizedBox(width: 13),
            Expanded(child:
            Text(
              "Image Verified!",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ));
      if (userId != null && firstName != null) {
        UserData.warning= reason;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => bodymeasurements(
              image: _image!,
              userId: userId!,
              firstName: firstName!,
              warning: reason,
            ),
          ),
        );
      }
    }

    else if (status == 'warning' || status == 'note') {

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent),
                      SizedBox(width: 10),
                      Text(
                        "Image Verified!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _clearimage();
                          _pickImage(ImageSource.gallery);// Resubmit image
                        },
                        child: const Text(
                          "Redo",
                          style: TextStyle(color: Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (userId != null && firstName != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => bodymeasurements(
                                  image: _image!,
                                  userId: userId!,
                                  firstName: firstName!,
                                  warning: reason,
                                ),
                              ),
                            );
                          }





                        },

                        child: const Text(
                          "Proceed",
                          style: TextStyle(color: Colors.greenAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      );
    }

    else if (status == 'error') {
      _clearimage(); // remove image
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.redAccent),
                const SizedBox(width: 13),
                Expanded(child:
                Text(
                  "❌ $reason",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),),
              ],
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)
            ),
            duration: const Duration(seconds: 15),
            action: SnackBarAction(label: "Redo", onPressed: ()=> _pickImage(ImageSource.gallery)),
          )
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isloading) return; // 🛑 Prevent double taps
    setState(() {
      _isloading = true;
    });

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage == null) {
      setState(() {
        _isloading = false;
      });
      return;
    }

    File originalFile = File(pickedImage.path);

    if (!await originalFile.exists() || await originalFile.length() == 0) {
      setState(() {
        _isloading = false;
      });
      throw Exception("❌ Resized image is empty or corrupted.");
    }

    setState(() {
      _image = originalFile;
    });
    await Future.delayed(const Duration(milliseconds: 20)); // so that setstate is being called
    await _submitImage(originalFile);

    setState(() {
      _isloading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final args = route?.settings.arguments as Map<String, dynamic>?;

     userId = args?['userID'];
     firstName = args?['firstname'];

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("User ID not found.")),
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
            child: TweenAnimationBuilder(
              tween: Tween<Offset>(begin: const Offset(0, 100), end: Offset.zero),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, Offset offset, child) {
                return Transform.translate(
                  offset: offset,
                  child: child,
                );
              },

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

                    // --- Instruction Text Container (FIXED SYNTAX HERE) ---

                    Center(
                   child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      margin: const EdgeInsets.only(bottom: 25, top: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC7B1E4),
                        borderRadius: BorderRadius.circular(15),
                        // Removed: border: Border.all(color: Colors.purple, width: 2)
                      ),

                      child: Text( // Now the direct child
                        "Please upload an image to find your\nheight, weight, age and gender",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins( // Using Poppins
                          color: const Color(0xFF341539), // Darker text
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ),

                    const SizedBox(height: 40), // Reduced spacing from 130 to 40

                    // --- "UPLOAD" Dotted Border Option ---
                    Center(
                      child: DottedBorder(
                        color: const Color(0xFF6A1B9A), // Darker purple
                        strokeWidth: 3, // Thinner stroke
                        dashPattern: const [6, 4], // Smaller dashes
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(16), // More rounded
                        child: InkWell(
                          onTap: () => _pickImage(ImageSource.gallery),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 330,
                            width: MediaQuery.of(context).size.width * 0.75, // Responsive width
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _image != null // Conditional display for selected image thumbnail
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                                : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.photo_library,
                                    color: Color(0xFF6A1B9A),
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Upload from Gallery",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25), // Space between Upload and OR

                    // --- "OR" Differentiator

                      Center(
                       child:  Text(
                          "OR",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF341539),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),



                    const SizedBox(height: 25), // Space between OR and Camera

                    // --- "CAMERA" Button Option ---
                    Center(
                      child: SizedBox(
                        height: 50, // Standard button height
                        width: MediaQuery.of(context).size.width * 0.75, // Match width with dotted border
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A), // Consistent accent color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), // Match corner radius
                            ),
                            elevation: 5,
                            shadowColor: Colors.black.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: Text(
                            "Take Photo with Camera",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40), // Spacing above the Analyze button

                    // --- "ANALYZE IMAGE" Button ---

                   // Pushes the "Go Back" button to the bottom
                    Center(
                   child:  ElevatedButton(
                     onPressed: ()  {
                       // FOR PRODUCTION UNCOMMENT THIS LINE!
                      // Navigator.push(context, MaterialPageRoute(builder: (context)=> Introdpage1()) );
                       // your next step logic
                       // Only for testing before testing make it Navigator pop
                      Navigator.push(context,
                         MaterialPageRoute(builder: (context) => UserHealthInfo(firstName: firstName, userId:userId)),);
                     },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF341539),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      ),

                      child: const Text(
                        "Go Back",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                    )
                  ],
                ),
              ),
            ),
          ),
          )
          )
        ],
      ),
    );
  }
}
