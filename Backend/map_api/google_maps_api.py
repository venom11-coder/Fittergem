from flask import Flask, jsonify # importing flask 
from flask import request
from datetime import datetime
import os
from dotenv import load_dotenv
import requests

app = Flask(__name__)

load_dotenv()



API_KEY = os.getenv("MAP_API_KEY")

# Google's Reverse Geocoding API  
# takes longitutde and latitude and returns the city 

 # constructor that initialises the flask to the app

@app.route("/location", methods=["POST"]) # defines route when clicked on the url
def get_location():
  
 data = request.get_json()
 lon= data.get("longitude")
 lati =data.get("latitude")

 if not lati or lon:
     return jsonify(status="error",message="invalid or missing coordinates!"), 400
  
  # calling the google maps to get exact location now
 url = f"https://maps.googleapis.com/maps/api/geocode/json?latlng={lati},{lon}&key={API_KEY}"
 response = requests.get(url)
 location = response.json()

 try:
   city = location["results"][0]["formatted_address"]
   return jsonify(city=city)
 except Exception as e:
     return jsonify(status="error", message="invalid location!")

@app.route("/timezone", methods=['POST'])
def get_timezone():
   
  data = request.get_json()
  lon= data.get("longitude")
  lati =data.get("latitude")

  if not lon or not lati:
    return jsonify(status="error", message="could not find coordinates!")
 
  timestamp = int(datetime.utcnow().timestamp())
  url = f"https://maps.googleapis.com/maps/api/timezone/json?location={lati},{lon}&timestamp={timestamp}&key={API_KEY}"

  response = requests.get(url)
  timezone_data = response.json()
  if timezone_data.get("status") != "OK":
        return jsonify({"error": "Could not fetch timezone"}), 400

  return jsonify(timeZoneId=timezone_data["timeZoneId"])


@app.route("/restraunts", methods=['POST'])
def get_restaurants():
    url = f"https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    data = request.get_json()
    lon= data.get("longitude")
    lati =data.get("latitude")
    params = {
        "location": f"{lati},{lon}",
        "radius": 2000,
        "type": "restaurant",
        "key": API_KEY
    }
    response = requests.get(url, params=params)
    places= response.json()

    restaurants = []
    for place in places.get("results", [])[:15]:  # Get top 15
        name = place.get("name")
        address = place.get("vicinity")
        rating = place.get("rating")
        restaurants.append({
            "name": name,
            "address": address,
            "rating": rating
        })

    return jsonify(restaurants=restaurants)


if(__name__ == "__main__"): 
   port = int(os.environ.get("PORT", 5000))
   app.run(host="0.0.0.0", port=port, debug=True)
 



    
