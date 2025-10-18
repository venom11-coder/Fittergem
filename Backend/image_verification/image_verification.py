
import os
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"
os.environ["MEDIAPIPE_DISABLE_GPU"] = "true"
import mediapipe as mp
from flask import jsonify
from flask import Flask
from flask import request
import cv2
import imghdr
from PIL import Image
from pillow_heif import read_heif
import math
from flask import Flask, request
import numpy as np
from io import BytesIO

app = Flask(__name__)




 
# all the important points of the body
nose = mp.solutions.pose.PoseLandmark.NOSE.value # for nose
ankle_Left = mp.solutions.pose.PoseLandmark.LEFT_ANKLE.value # for ankle 
ankle_Right = mp.solutions.pose.PoseLandmark.RIGHT_ANKLE.value # for right ankle
shoulder_Right = mp.solutions.pose.PoseLandmark.RIGHT_SHOULDER.value # for right shoulder
shoulder_Left = mp.solutions.pose.PoseLandmark.LEFT_SHOULDER.value # for left shoulder
knee_Left= mp.solutions.pose.PoseLandmark.LEFT_KNEE.value # for left knee
wrist_Left = mp.solutions.pose.PoseLandmark.LEFT_WRIST.value # left wrist
wrist_Right = mp.solutions.pose.PoseLandmark.RIGHT_WRIST.value # right wrist
Hip_Left = mp.solutions.pose.PoseLandmark.LEFT_HIP.value # for left hip needed for angle of if user is bend or not
ANKLE_LEFT= mp.solutions.pose.PoseLandmark.LEFT_ANKLE.value # for ankle
NOSE= mp.solutions.pose.PoseLandmark.NOSE.value #  of Nose 
SHOULDER_LEFT= mp.solutions.pose.PoseLandmark.LEFT_SHOULDER.value # for Shoulder




# pose



 
 
 
@app.route("/Verification", methods=['POST'])
def image_processing():
 
 # request from flutter
 file = request.files["image"]
 if file is None or file.filename=='' :
   return jsonify(status="error", reason="the image seems corrupted", retry="yes"), 400
 raw = file.read()
 #file.seek(0)

 file_type = imghdr.what(None, h=raw)

 # gets the extension
 file_ext = file.filename.lower()

 # handles if heic or heif format
 try:
        if file_type in ["heic", "heif"]:
            heif_file = read_heif(raw)
            image_pil = Image.frombytes(
                heif_file.mode, heif_file.size, heif_file.data, "raw"
            )
            buffer = BytesIO()
            image_pil.save(buffer, format="JPEG")
            buffer.seek(0)
            file_bytes = np.asarray(bytearray(buffer.read()), dtype=np.uint8)
            image = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
        else:
            file_bytes = np.frombuffer(raw, np.uint8)
            image = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

 except Exception as e:
        return jsonify(status="error", reason=f"Invalid image format or corrupt image. Error: {str(e)}", retry="yes")

 
 # if resolution is too high
 MAX_DIM = 1280
 height, width = image.shape[:2]

 if max(height, width) > MAX_DIM:
    scale = MAX_DIM / max(height, width)
    new_size = (int(width * scale), int(height * scale))
    image = cv2.resize(image, new_size, interpolation=cv2.INTER_AREA)


 


 # converts from BGR to RGB
 image_converted = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

 # PROCESSES THE CONVERTED IMAGE(RGB)
 
 result = pose.process(image_converted) 
 # change it to request image AGAIN!!
 if image is None:
  return jsonify(status="error", reason= "Could not load the image!", retry= "yes") 

 if result is None:
  return jsonify (status="error", reason= "could not convert the image to the required format!", retry="yes") 
 try:
  landmarks = result.pose_landmarks.landmark
 except Exception:
  return jsonify (status="error", reason= "could not find a face!", retry="yes") 
 
 gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
 Brightness = np.mean(gray_image)
 height, width = gray_image.shape
 
 #return jsonify("Brightness": Brightness)
 if Brightness < 50 or Brightness> 200:
  return jsonify (status="note" ,reason= "The image is either too bright or less bright!", retry="optional")

 
 # for calculation of angle to see if user is bend or not
 A= landmarks[shoulder_Left]
 B= landmarks[Hip_Left]
 C= landmarks[knee_Left]


 # Y-Axis measurement of landmarks
 NOSE_Y= landmarks[NOSE].y 
 ANKLE_LEFT_Y= landmarks[ANKLE_LEFT].y
 SHOULDER_LEFT_Y= landmarks[SHOULDER_LEFT].y

 hip_vis = (landmarks[Hip_Left].visibility + landmarks[hip_right_pixels].visibility) / 2
 shoulder_vis = (landmarks[shoulder_Left].visibility + landmarks[shoulder_Right].visibility) / 2

 #for debugging only
 print("hip visibility", hip_vis)
 print("shoulder visibilty", shoulder_vis)

 BODY_RATIO= (ANKLE_LEFT_Y-NOSE_Y)/ (SHOULDER_LEFT_Y-NOSE_Y)

 #for debugging only
 #return jsonify(BODY_RATIO)

# helps to detect face selfies as hip visibility will be very less
 if hip_vis < 0.3 and shoulder_vis > 0.5:
  return jsonify(status="error", reason="please upload full body image!", retry="yes")
 
 if BODY_RATIO > 9.1:
  return jsonify(status="warning" ,reason=" The image seems to be a little too close!", retry="optional")


 
  # converting these values into vector
 a = np.array([A.x, A.y])
 b = np.array([B.x, B.y])
 c = np.array([C.x, C.y])
  

  # find vector distance from 1 point to another
  # v1: vector from hip to shoulder
  # v2: vector from hip to knee

 v1 = a-b 
 v2 = c-b
 cos_theta = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))
 cos_theta = np.clip(cos_theta, -1.0, 1.0)
 angle = math.degrees(math.acos(cos_theta))

 # for DEBUGGING
 #return jsonify(angle)

 if angle < 171 and angle >=150:
  return jsonify(status="note" ,reason="You seem a little bent, this could maybe lead to minor inaccuracy in prediction of height!", retry="optional")

 elif angle < 150 and angle >= 130:
    return jsonify(status="warning", reason= "You seem a slightly bent, this could possibly lead to inaccurate prediction of height!", retry="optional")

 elif angle < 130:
    return jsonify(status="error" ,reason= "You seem a too bent, this could maybe lead to inaccurate prediction of height!", retry="yes") 

 
 
  
 
 # only for debugging to return jsonify all visibility of all 33 landmarks
 #for i, lm in enumerate(landmarks):
    #return jsonify(f"Landmark i: visibility = lm.visibility")

 if landmarks is not None:
  if landmarks[nose].visibility < 0.45:
   return jsonify (status="error", reason= "the image seems incomplete!", retry="yes")
   
  
  elif landmarks[shoulder_Left].visibility < 0.45:
    return jsonify (status="error", reason= "the image seems incomplete!", retry="yes")
    
  
  elif landmarks[ankle_Left].visibility < 0.45:
    return jsonify (status="error", reason= "the image seems incomplete!", retry="yes")
    
  
  elif landmarks[ankle_Right].visibility < 0.5:
    return jsonify (status="error", reason= "the image seems incomplete!", retry="yes")
    
  
  elif landmarks[shoulder_Right].visibility < 0.5:
    return jsonify (status="error", reason="the image seems incomplete!", retry="yes")
    
  
  elif landmarks[wrist_Right]. visibility < 0.5:
   return jsonify (status="error", reason= "the image seems incomplete!", retry="yes")
   
  

  
  shoulder_Right_Y= landmarks[shoulder_Right].y
  shoulder_Left_Y= landmarks[shoulder_Left].y 
  knee_Left_Y= landmarks[knee_Left].y
  ankle_Left_Y= landmarks[ankle_Left].y


  if shoulder_Left_Y > knee_Left_Y or shoulder_Left_Y > ankle_Left_Y:
   return jsonify (status="error", reason=" you seem to have a sitting position. This could lead to inaccurate results!", retry="yes")
   
  
  if abs(shoulder_Left_Y - shoulder_Right_Y) > 0.05:
   return jsonify (status="error", reason="you seem to have a little bend position. This could lead to inaccurate results!", retry="yes")

  
  return jsonify(status="success", reason="Image satisfies all the requirements")
 

if __name__== "__main__":
  port = int(os.environ.get("PORT", 5000))
  app.run(host="0.0.0.0", port=port)
   

  

