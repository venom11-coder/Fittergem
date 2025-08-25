from flask import Flask, request, jsonify
from insightface.app import FaceAnalysis
import mediapipe as mp
import os
import cv2
from openai import OpenAI
import json
import base64
import re

# estimates the age gender height and weight
# uses flask
#however will switch to fastAPI
# will work for atleast 1000 users at a time

# creates a flask object
app = Flask(__name__)

# api key inside the server
api_key = os.getenv("api_key")

#activates the api key
client = OpenAI(api_key=api_key)





# creates a post request
@app.route("/predict", methods=['POST'])
def find_image():

    print("✅ /predict endpoint called")
    
    # if none of the user id or image is not found
    if "image" not in request.files:
        return jsonify(status="error", message= "The image is missing!"), 400

    if "user_id" not in request.form:
        return jsonify(status="error", message= "The user-id is missing!"), 400
    
    # activates the faceanalysis 
    model = FaceAnalysis()
    model.prepare(ctx_id=-1)

    # activates the mediapipe
    pose = mp.solutions.pose.Pose()

    # values from 0-1
    nose_pixels = mp.solutions.pose.PoseLandmark.NOSE.value
    ankle_pixels = mp.solutions.pose.PoseLandmark.LEFT_ANKLE.value
    ankle_right_pixels = mp.solutions.pose.PoseLandmark.RIGHT_ANKLE.value
    shoulder_pixels = mp.solutions.pose.PoseLandmark.LEFT_SHOULDER.value
    shoulder_right_pixels = mp.solutions.pose.PoseLandmark.RIGHT_SHOULDER.value
    hip_pixels = mp.solutions.pose.PoseLandmark.LEFT_HIP.value
    hip_right_pixels = mp.solutions.pose.PoseLandmark.RIGHT_HIP.value
    knee_pixels = mp.solutions.pose.PoseLandmark.LEFT_KNEE.value
    knee_right_pixels = mp.solutions.pose.PoseLandmark.RIGHT_KNEE.value
    wrist_pixels = mp.solutions.pose.PoseLandmark.RIGHT_WRIST.value
    elbow_pixels = mp.solutions.pose.PoseLandmark.LEFT_ELBOW.value
    
    # requests the image and used id and then saves it using temp file
    image_file = request.files["image"]
    warning = request.form.get("warning","").strip()
    print("got image!")
    image_save_path = f"/tmp/{request.form['user_id']}_upload.jpg"
    image_file.save(image_save_path)
    image = cv2.imread(image_save_path)

    # gets the age and gender in a list
    face = model.get(image)
    age = int(face[0].age)
    gender = face[0].gender
    gender = "female" if gender == 0 else "male"

    # then converts the file from BGR to RGB for mediapipe
    image_converted = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    result = pose.process(image_converted)
    
    # the landmarks are found
    if result.pose_landmarks is not None:
        landmark = result.pose_landmarks.landmark
        
        # finds the landmarks of all the required measurements for calculations
        hip_pixels_y = landmark[hip_pixels].y
        nose_y = landmark[nose_pixels].y
        ankle_y = landmark[ankle_pixels].y
        hip_pixels_x = landmark[hip_pixels].x
        hip_right_pixels_x = landmark[hip_right_pixels].x
        shoulder_pixels_x = landmark[shoulder_pixels].x
        shoulder_right_pixels_x = landmark[shoulder_right_pixels].x
        ankle_pixels_x = landmark[ankle_pixels].x
        ankle_right_pixels_x = landmark[ankle_right_pixels].x
        shoulder_pixels_y = landmark[shoulder_pixels].y

        image_height = image.shape[0]
        nose_y_pixels = image_height * nose_y
        ankle_y_pixels = image_height * ankle_y
        distance_pixels = ankle_y_pixels - nose_y_pixels
        
        # assumes the length from nose to top of head
        head_cms = 20.5

        # shoulder width
        shoulder_y_pixels = image_height * shoulder_pixels_y
        head_pixel_height = shoulder_y_pixels - nose_y_pixels
        scale_cm_per_pixel = head_cms / head_pixel_height
        
        # finds height in cm and m
        height_cm = distance_pixels * scale_cm_per_pixel
        height_m = height_cm / 100

        # finds shoulder ankle and hip width for weight estimation
        shoulder_width = abs(shoulder_pixels_x - shoulder_right_pixels_x) * height_m
        hip_width = abs(hip_pixels_x - hip_right_pixels_x) * height_m
        ankle_width = abs(ankle_pixels_x - ankle_right_pixels_x) * height_m
                          
        # extracts the extension of the image
        extension = os.path.splitext(image_save_path)[1].lower().replace(",", "")
        if extension == ".jpg":
            extension = ".jpeg"
        extension = extension.replace(".", "")
        
        # opens the file in binary
        with open(image_save_path, "rb") as file:
            binary_data = file.read()
        
        # ASCII
        Base64_String = base64.b64encode(binary_data).decode("utf-8")

        
        
        # SENDS THE MESSAGE TO AI 
        try:
            completion = client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": (
                                    f"This person has the following body metrics derived from computer vision:\n"
                                    f"- Apparent age from face: {age} years\n"
                                    f"- Gender: {gender}\n"
                                    f"- Shoulder width: {shoulder_width:.4f} meters\n"
                                    f"- Hip width: {hip_width:.4f} meters\n"
                                    f"- Ankle width: {ankle_width:.4f} meters\n"
                                    f"- Vertical nose-to-ankle pixel distance: {distance_pixels:.2f}\n"
                                    f"- Full image height: {image_height} pixels\n\n"
                                    +(f"- ⚠️ Warning (based on image analysis): {warning}\n" if warning else "")+
                                    "Using this data, please estimate the user's:\n"
                                    "you need to return the height and weight no matter what nothing just strictly in the format mentioned \n"
                                    "Do NOT wrap it in triple backticks or say anything else.\n"
                                    "I just need the height and weight of the user nothing else at all\n"
                                    "1. Height (in centimeters)\n"
                                    "2. Weight (in kilograms)\n\n"
                                    "Return the result as strict JSON in this format:\n"
                                    
                                   "{\"height_cm\": 178.5, \"weight_kg\": 72.2}\n"
                                   "the result should be as accurate as possible.\n"
                                    "**Return ONLY the JSON. No explanation or extra text.**"
                                )
                            }
                        ]
                    }
                ]
            )

            # gets the reply from AI
            gpt_reply = completion.choices[0].message.content.strip()

            try:
                reply_float = json.loads(gpt_reply)
                height_cm = reply_float["height_cm"]
                weight = reply_float["weight_kg"]
            except Exception as e:
                height_final = re.search(r'"height_cm"\s*:\s*([0-9.]+)', gpt_reply)
                weight_final = re.search(r'"weight_kg"\s*:\s*([0-9.]+)', gpt_reply)
                if height_final and weight_final:
                    height_cm = float(height_final.group(1))
                    weight = float(weight_final.group(1))
                else:
                    return jsonify(status="error", message="Failed to extract height/weight from GPT reply")
        
        # if API connection fails
        except Exception as e:
            return jsonify(status="error", message= "Weight estimation failed"), 500
        
        # removes the image no matter what
        finally:
            if os.path.exists(image_save_path):
              os.remove(image_save_path)


        # dictionary for all measurements
        # stores the measurements
        analysis = {
            "age": age,
            "gender": gender,
            "height_cm": round(height_cm, 2),
            "weight": round(weight,2)
        }
        
        
        # returns the dictionary
        return jsonify(analysis)
     
     # if no landmark is found then returns
    else:
        return jsonify(status="error", message= "No landmarks found please try again!"), 400


# starts the flask server on railway
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))

