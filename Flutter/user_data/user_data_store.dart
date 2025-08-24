import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
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

class UserData{

  static String? fullname= "";
  static String userId = "";
  static String firstname = "";
  static String? warning = "";
  static String? email = "";
  static String? name = "";
  static String? gender = "";
  static int? age = 0;
  static bool? redirect =false;
  static File? image;
  static double height = 0.0;
  static double? weight = 0.0;
  static List<String> diseases = [];
  static bool Locationaccessed = false;
  static bool? healthdataaccess = false;
  static bool? calenderaccess = false;
  static String? sleephours = "";
  static double motivationLevel = 5;
  static String? workoutFrequency = "";
  static double veganPercent = 0;
  static double vegetarianPercent = 0;
  static double nonVegPercent = 100;
  static List<String> cuisines = [];
  static String restrictionText = "None";
  static bool? FinalPage = false;
}
