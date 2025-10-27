from openai import OpenAI
import os
import openai
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, Text, Integer, DateTime, desc
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declarative_base 
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from fastapi import FastAPI, Request, File, UploadFile, Form
from fastapi.responses import JSONResponse
import json
#import tempfile
#from PIL import Image
from typing import Annotated, List, Literal, Optional
import base64
#import re
import httpx

app = FastAPI()

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Use specific domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



# makes a base class to deploy the db
base = declarative_base()

# ai api key
api_key = os.getenv("api_key")

# connects to the db
DATABASE_URL = os.getenv("DATABASE_URL")

# creates an engine
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine)

class FinalUserInfo(base):
    __tablename__ = 'finaluserinfo'
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Text)
    full_name = Column(Text)
    age = Column(Text)
    height = Column(Text)
    weight = Column(Text)
    gender = Column(Text)
    diseases = Column(Text)
    health_info = Column(Text)
    timezone = Column(Text)
    restaurants = Column(Text)
    events_calendar = Column(Text)
    favorite_cuisines = Column(Text)
    other_restrictions = Column(Text)
    diet_percentage = Column(Text)
    workout_plan = Column(JSONB)
    diet_plan = Column(JSONB)
    cheat_meal_plan = Column(JSONB)
    timestamp = Column(DateTime, default=datetime.now)


# creates a table for storing user feeback
class UserFeedback(base):
    __tablename__ = 'userfeedback'
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Text)
    feedback = Column(Text)
    timestamp = Column(DateTime, default=datetime.now)


# creates a table for storing chats
class Chat(base):
    __tablename__ = 'Chat'
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Text)
    input_text = Column(Text)
    output_text = Column(Text)
    timestamp = Column(DateTime, default=datetime.now)



# for storing bugs and work on them
class BugsDB(base):
    __tablename__ = 'bugsdb'
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Text)
    bug_description = Column(Text)
    timestamp = Column(DateTime, default=datetime.now)



# passes into the db
base.metadata.create_all(engine)

# exact structure for generating the json file for workout plan
class WorkoutPlan(BaseModel):
    day: str
    main_focus_for_the_day: str
    exercise_1_name: str
    sets_exercise_1: str
    reps_in_each_set_exercise_1: str
    time_devoted_to_exercise_1: str
    tutorial_exercise_1: str
    remarks_or_instructions_exercise_1: str
    exercise_2_name: str
    sets_exercise_2: str
    reps_in_each_set_exercise_2: str
    time_devoted_to_exercise_2: str
    tutorial_exercise_2: str
    remarks_or_instructions_exercise_2: str
    exercise_3_name: Optional[str]
    sets_exercise_3: Optional[str]
    reps_in_each_set_exercise_3: Optional[str]
    time_devoted_to_exercise_3: Optional[str]
    tutorial_exercise_3: Optional[str]
    remarks_or_instructions_exercise_3: Optional[str]
    exercise_4_name: Optional[str]
    sets_exercise_4: Optional[str]
    reps_in_each_set_exercise_4: Optional[str]
    time_devoted_to_exercise_4: Optional[str]
    tutorial_exercise_4: Optional[str]
    remarks_or_instructions_exercise_4: Optional[str]
    exercise_5_name: Optional[str]
    sets_exercise_5: Optional[str]
    reps_in_each_set_exercise_5: Optional[str]
    time_devoted_to_exercise_5: Optional[str]
    tutorial_exercise_5: Optional[str]
    remarks_or_instructions_exercise_5: Optional[str]
    final_remarks_for_the_day: str

# creates a list of workout plans
class WorkoutPlanList(BaseModel):
    plan: List[WorkoutPlan]

# for updating the workout plan
# will follow the exact same format just return status to indentify
class WorkoutPlanUpdate(BaseModel):
    status: Literal["workout_plan_update"]
    plan: List[WorkoutPlan]

# for creating the diet plan
class DietPlan(BaseModel):
  day: str
  breakfast: str
  breakfast_quantity: str
  breakfast_recommended_time: str
  breakfast_remarks: str
  lunch: str
  lunch_quantity: str
  lunch_recommended_time: str
  lunch_remarks: str
  snacks: str
  snacks_quantity: str
  snacks_recommended_time: str
  snacks_remarks: str
  dinner: str
  dinner_quantity: str
  dinner_recommended_time: str
  dinner_remarks: str
  final_remarks_for_the_day: str

# creates a list of diet plans
class DietPlanList(BaseModel):
    plan: List[DietPlan]

# for updating the diet plan
class DietPlanUpdate(BaseModel):
    status: Literal["diet_plan_update"]
    plan: List[DietPlan]

# for generating cheat meal plan
class CheatMealPlan(BaseModel):
    restaurant: str
    address: str
    recommended_meals: str
    remarks:str

# creates a list of cheat meal plans
class CheatMealPlanList(BaseModel):
    plan: List[CheatMealPlan]

# creates a class for all plans
class AllPlans(BaseModel):
    workout_plan: WorkoutPlanList
    diet_plan: DietPlanList
    cheat_meal_plan: CheatMealPlanList

class WorkoutDietPlanOnly(BaseModel):
    workout_plan: WorkoutPlanList
    diet_plan: DietPlanList

# for updating cheat meal plan
class CheatMealPlanUpdate(BaseModel):
    status: Literal["cheat_meal_plan_update"]
    plan: List[CheatMealPlan]

# for adding events to the calendar
class CalendarEventAdd(BaseModel):
    summary: str
    event: str
    time_start: str
    time_end: str
    timeZone: str

class CalendarEventAddList(BaseModel):
    events: List[CalendarEventAdd]


@app.post("/storing-feedback")
async def storing_feedback(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    feedback = data["feedback"]

    try:
       
           new_feedback = UserFeedback(
            user_id=user_id,
            feedback=feedback
           )
           session.add(new_feedback)
           session.commit()
    
    # closes the db no matter what
    finally:
        session.close()

# for storing user reported bugs
@app.post("/storing-user-reported-bug")
async def storing_user_reported_bug(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    bug_description = data["bug_description"]

    try:
        new_bug = BugsDB(
            user_id=user_id,
            bug_description=bug_description
        )
        session.add(new_bug)
        session.commit()
    
    # closes the db no matter what
    finally:
        session.close()
 
# for updating the user_info
@app.post("/body-measurements-store")
async def user_body_measurements_update(request:Request):
  session = SessionLocal()
  data = await request.json()
  user_id = data["user_id"]
  age =  data["age"]
  weight = data["weight"]
  height = data["height"]
  gender = data["gender"]
  full_name = data["full_name"]


  try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
      
      # if the user exists then updates the info 
      if user_exist:
          user_exist.age = age
          user_exist.gender = gender
          user_exist.height = height
          user_exist.weight = weight
          user_exist.full_name = full_name
 
      # if the user does not exist then adds them to the table
      else:
          new_user= FinalUserInfo(user_id=user_id,
                                full_name= full_name,
                                age=age,
                                gender= gender,
                                height = height,
                                weight= weight,
                                 )
          session.add(new_user)
      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
  except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}
  
  # closes the db no matter what
  finally:
      session.close()



# for saving the user diseases inputted
#WORKING!!!
@app.post("/user-diseases-store")      
async def user_diseases_update(request:Request):
  session = SessionLocal()
  data = await request.json()
  user_id = data["user_id"]
  diseases = data["diseases"]

  try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()

       # if the user exists then updates the info
      if user_exist:
          user_exist.diseases = diseases
 
     # creates a new user if not found
     
      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
  except Exception as e:
   session.rollback()
   return {"status": "error", "message": str(e)}
  
  # closes the db no matter what
  finally:
      session.close()

# WORKS!!!!
@app.post("/user-health-data-store")
async def user_health_data_store(request:Request):
    session = SessionLocal()
    # gets the user data from the request
    data = await request.json()
    user_id = data["user_id"]
    health_info = data["health_info"]
    
    try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
      
      if user_exist:
          user_exist.health_info = health_info

      
      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
    except Exception as e:
     session.rollback()
     return {"status": "error", "message": str(e)}
  
  # closes the db no matter what
    finally:
      session.close()

# WORKS!!!!            
@app.post("/user-location-data-store")
async def user_location_data_store(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    timezone = data["timezone"]
    restaurants = data["restaurants"]
    
    try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
      
      if user_exist:
          user_exist.timezone = timezone
          user_exist.restaurants = restaurants

     
          
      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
    except Exception as e:
     session.rollback()
     return {"status": "error", "message": str(e)}
    
    #closes the db no matter what
    finally:
        session.close()

@app.post("/user-calendar-data-store")
async def user_calendar_data_store(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    events = data["events"]
    
    try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
      
      if user_exist:
          user_exist.events_calendar = events

     
      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
    except Exception as e:
     session.rollback()
     return {"status": "error", "message": str(e)}
    
    #closes the db no matter what
    finally:
        session.close()

@app.post("/user-diet-preferences-store")
async def user_diet_preferences_store(request:Request): 
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    favorite_cuisines = data["favorite_cuisines"]
    other_restrictions = data["other_restrictions"]
    diet_percentage = data["diet_percentage"]
    
    try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
      
      if user_exist:
          user_exist.favorite_cuisines = favorite_cuisines
          user_exist.other_restrictions = other_restrictions
          user_exist.diet_percentage = diet_percentage

      
      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
    except Exception as e:
     session.rollback()
     return {"status": "error", "message": str(e)}
    
    #closes the db no matter what
    finally:
        session.close()

@app.post("/user-location-data-remove")
async def user_location_data_remove(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    
    try:
        # checks if user exists or not
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        
        if user_exist:
            user_exist.timezone = None
            user_exist.restaurants = None
            session.commit()
            return JSONResponse({"status": "removed", "message": "removed user location data"})
        else:
            return JSONResponse({"status": "not_found", "message": "user location data not found"})
    
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}
    
    # closes the db no matter what
    finally:
        session.close()



@app.post("/user-diseases-remove")
async def user_diseases_remove(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    
    try:
        # checks if user exists or not
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        
        if user_exist:
            user_exist.diseases = "None"
            session.commit()
            return JSONResponse({"status": "removed", "message": "removed user diseases"})
        else:
            return JSONResponse({"status": "not_found", "message": "user diseases not found"})
    
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}
    
    # closes the db no matter what
    finally:
        session.close()

@app.post("/user-calendar-data-remove")
async def user_calendar_data_remove(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    
    try:
        # checks if user exists or not
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        
        if user_exist:
            user_exist.events = "Access not given by user"
            session.commit()
            return JSONResponse({"status": "removed", "message": "removed user calendar data"})
        else:
            return JSONResponse({"status": "not_found", "message": "user calendar data not found"})
    
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}
    
    # closes the db no matter what
    finally:
        session.close()

# returns the existing workout plan of the user
@app.post("/user-workout-plan")
async def user_workout_plan(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    
    try:
        # checks if user exists or not
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        
        if user_exist:
            workout_plan = user_exist.workout_plan
            if workout_plan:
                return JSONResponse({"status": "success", "workout_plan": workout_plan})
            else:
                return JSONResponse({"status": "not_found", "message": "workout plan not found"})
        else:
            return JSONResponse({"status": "not_found", "message": "user not found"})
    
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}
    
    # closes the db no matter what
    finally:
        session.close()

# returns the existing diet plan of the user
@app.post("/user-diet-plan")
async def user_diet_plan(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    
    try:
        # checks if user exists or not
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        
        if user_exist:
            diet_plan = user_exist.diet_plan
            if diet_plan:
                  # Debugging line
                return JSONResponse({"status": "success", "diet_plan": diet_plan})
            else:
                 # Debugging line
                return JSONResponse({"status": "not_found", "message": "diet plan not found"})
        else:
            print("User not found:", user_id)  # Debugging line
            return JSONResponse({"status": "not_found", "message": "user not found"})
    
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}
    
    # closes the db no matter what
    finally:
        session.close()

@app.post("/user-cheat-meal-plan")
async def user_cheat_meal_plan(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    
    try:
        # checks if user exists or not
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        
        if user_exist:
            cheat_meal_plan = user_exist.cheat_meal_plan
            if cheat_meal_plan:
                return JSONResponse({"status": "success", "cheat_meal_plan": cheat_meal_plan})
            else:
                return JSONResponse({"status": "not_found", "message": "cheat meal plan not found"})
        else:
            return JSONResponse({"status": "not_found", "message": "user not found"})
    
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}
    
    # closes the db no matter what
    finally:
        session.close()

# removes all the information of the user
@app.post("/")
async def sign_out(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]

    # remvoves all the chats of the user from the chat table
    try:
        user_chat = session.query(Chat).filter_by(user_id=user_id).all()
        for chat in user_chat:
            session.delete(chat)
        session.commit()
    finally:
        session.close()
    
    try:
        # checks if user exists or not
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        
        if user_exist:
            session.delete(user_exist)
            session.commit()
            return JSONResponse({"status": "success", "message": "user signed out and data removed"})
        else:
            return JSONResponse({"status": "not_found", "message": "user not found"})
    
    except Exception as e:
        session.rollback()
        return {"status": "error", "message": str(e)}
    
    # closes the db no matter what
    finally:
        session.close()


@app.post("/user-workout-plan-store")
async def user_workout_plan_store(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    workout_plan = data["workout_plan"]
    
    try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
      
      if user_exist:
          user_exist.workout_plan = workout_plan

      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
    except Exception as e:
     session.rollback()
     return {"status": "error", "message": str(e)}
    
    #closes the db no matter what
    finally:
        session.close()
 
 
@app.post("/user-diet-plan-store")
async def user_diet_plan_store(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    diet_plan = data["diet_plan"]
    
    try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
      
      if user_exist:
          user_exist.diet_plan = diet_plan

      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
    except Exception as e:
     session.rollback()
     return {"status": "error", "message": str(e)}
    
    #closes the db no matter what
    finally:
        session.close()

@app.post("/user-cheat-meal-plan-store")
async def user_cheat_meal_plan_store(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    cheat_meal_plan = data["cheat_meal_plan"]
    
    try:
      # checks if user exists or not
      user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
      
      if user_exist:
          user_exist.cheat_meal_plan = cheat_meal_plan

      
      session.commit()
      return JSONResponse({"status": "stored", "message": "stored user info"})
    except Exception as e:
     session.rollback()
     return {"status": "error", "message": str(e)}
    
    #closes the db no matter what
    finally:
        session.close()


# make this function a class instead which stores all these variables based on the user_id which is passed
async def get_all_user_info_string( user_id: str, session) -> str:
   

    user_id = str(user_id)  # Ensure user_id is a string
    try:
     user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()

     if user_exist:   

     
        # retrieves all the user info from FinalUserInfo table
       user_height_cm = user_exist.height
       user_weight = user_exist.weight
       user_gender = user_exist.gender
       user_age = user_exist.age
       user_full_name = user_exist.full_name
       plans_generation_time = user_exist.timestamp
       

       #retrieves all the user info from Diseases table
       user_diseases = user_exist.diseases
       

       # retrieves all the user info from HealthData table
       user_health_info = user_exist.health_info
       

       # retrieves all the user info from LocationData table
       user_timezone = user_exist.timezone
       user_nearby_restraurants = user_exist.restaurants
       
        
      # retrieves all the user info from CalendarData table
       user_events = user_exist.events_calendar
       

      # retrieves all the user info from DietPreferencesData table
       user_favorite_cuisines = user_exist.favorite_cuisines
       user_other_restrictions = user_exist.other_restrictions
       user_diet_percentage = user_exist.diet_percentage
       

     # retrieves all the user info from WorkoutPlan, DietPlan and CheatMealPlan table
       user_workout_plan = user_exist.workout_plan
       user_diet_plan = user_exist.diet_plan
       user_cheat_meal_plan = user_exist.cheat_meal_plan
      

        # creates a dictionary to store all the user info
        #returns the user info in string format
       user_info = {
       "full_name": user_full_name,
     "age": user_age if user_age else "Not provided",
     "gender": user_gender,
     "height_cm": user_height_cm,
     "weight": user_weight,
     "diseases": user_diseases if user_diseases else "None",
     "health_info": user_health_info,
     "timezone": user_timezone if user_timezone else "Not provided",
     "nearby_restaurants": user_nearby_restraurants if user_nearby_restraurants else "The user did not give access to their Location, if they ask questions regarding nearby restaurants or cheat meals, inform them that they have not given access to their location",
     "events_calendar": user_events if user_events else " The user did not give access to their calendar. If they ask you to adjust calendar events, inform them that they have not connected their calendar",
     "favorite_cuisines": user_favorite_cuisines,
     "other_restrictions": user_other_restrictions if user_other_restrictions else "None",
     "diet_percentage": user_diet_percentage,
     "workout_plan": user_workout_plan if user_workout_plan else "None or not yet made",
     "diet_plan": user_diet_plan if user_diet_plan else "None or not yet made",
     "cheat_meal_plan": user_cheat_meal_plan if user_cheat_meal_plan else "None, since the user did not give access to their location",
     "workout, diet and cheat plans generate at this time in UTC": plans_generation_time if user_workout_plan else "None",
      }

     user_info_json = json.dumps(user_info, indent=4)
     
     return user_info_json
    except Exception as e:
    
        return f"Error retrieving user info: {str(e)}"

#generates workout and diet plan only using structured output
@app.post("/user-workout-diet-generate")
async def user_workout_diet_generate(request: Request):
     session = SessionLocal()
     data = await request.json()
     user_id = data["user_id"]
     user_info = await get_all_user_info_string(user_id, session)

    # backend mapping for tutorial links
     EXERCISE_TUTORIALS = {
    "Push Ups": "https://www.youtube.com/watch?v=IODxDxX7oi4",
    "Squats": "https://www.youtube.com/watch?v=aclHkVaku9U",
    "Lunges": "https://www.youtube.com/watch?v=xqvCmoLULNY",
    "Planks": "https://www.youtube.com/watch?v=pSHjTRCQxIw",
    "Burpees": "https://www.youtube.com/watch?v=TU8QYVW0gDU",
    "Mountain Climbers": "https://www.youtube.com/watch?v=nmwgirgXLYM",
    "Jumping Jacks": "https://www.youtube.com/watch?v=c4DAnQ6DtF8",
    "High Knees": "https://www.youtube.com/watch?v=OAJ_J3EZkdY",
    "Tricep Dips": "https://www.youtube.com/watch?v=89_spgcdQlw",
    "Glute Bridges": "https://www.youtube.com/watch?v=Xp33YgPZgns",
    "Bicycle Crunches": "https://www.youtube.com/watch?v=9FGilxCbdz8",
    "Leg Raises": "https://www.youtube.com/watch?v=JB2oyawG9KI",
    "Superman": "https://www.youtube.com/watch?v=cc6UVRS7PW4",
    }


     message = (
        f"Generate a 14-day workout plan, diet plan, and cheat meal plan for the user based on the following information  and be quick:\n\n"
        f"{user_info}\n"
        )
     try:
        client = OpenAI(api_key=api_key)

        response = client.beta.chat.completions.parse(
            model="gpt-4o-2024-08-06",
            messages=[
                {"role": "system", "content": "You are Leo, a highly trained fitness expert. Analyse the user information provided deeply and generate a 14-day workout plan and diet plan. The plans should be highly user-friendly and only recommend home workouts. You can recommend at most 5 exercises per day for the workout plan. The only exercises you can recommend are push ups, squats, lunges, planks, burpees, mountain climbers, jumping jacks, high knees, tricep dips  glute bridges, bicycle crunches, leg raises and superman.\n"
                "for diet, consider the user's favorite cuisines, other restrictions, and diet percentage. The plans should be highly user-friendly and tailored to the user's preferences."
                "strictly follow the format provided for each plan.\n"
                "do not take too much time to generate the plans, be quick, accurate and efficient.\n"},
                 {"role": "user", "content": message}

            ],
            response_format=WorkoutDietPlanOnly,  # structured output
        )
     
        # Parse the response
        all_plans = response.choices[0].message.parsed  # type: AllPlans

        for day_plan in all_plans.workout_plan.plan:
            # Add tutorial links to each exercise
            if day_plan.exercise_1_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_1 = EXERCISE_TUTORIALS[day_plan.exercise_1_name]
            if day_plan.exercise_2_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_2 = EXERCISE_TUTORIALS[day_plan.exercise_2_name]
            if day_plan.exercise_3_name and day_plan.exercise_3_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_3 = EXERCISE_TUTORIALS[day_plan.exercise_3_name]
            if day_plan.exercise_4_name and day_plan.exercise_4_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_4 = EXERCISE_TUTORIALS[day_plan.exercise_4_name]
            if day_plan.exercise_5_name and day_plan.exercise_5_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_5 = EXERCISE_TUTORIALS[day_plan.exercise_5_name]

       

        workout_plan_json = all_plans.workout_plan.model_dump_json()
        diet_plan_json = all_plans.diet_plan.model_dump_json()
        
      

        # stores the workout plan in db
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        if user_exist:
            user_exist.workout_plan = workout_plan_json
            user_exist.diet_plan = diet_plan_json
            
        else:
            new_user = FinalUserInfo(
                user_id=user_id,
                workout_plan=workout_plan_json,
                diet_plan=diet_plan_json,
                
            )
            session.add(new_user)
        session.commit()
        return JSONResponse({
            "status": "success",
            "status": "success",
            "workout_plan": all_plans.workout_plan.model_dump(),
            "diet_plan": all_plans.diet_plan.model_dump(),
        })
     except Exception as e:
        session.rollback()
    
        return JSONResponse({"status": "error", "message": str(e)})
    
     finally:
        session.close()

    

# generates all 3 plans together using structured output
@app.post("/user-all-plans-generate")
async def user_all_plans_generate(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    user_info = await get_all_user_info_string(user_id, session)

    # backend mapping for tutorial links
    EXERCISE_TUTORIALS = {
    "Push Ups": "https://www.youtube.com/watch?v=IODxDxX7oi4",
    "Squats": "https://www.youtube.com/watch?v=aclHkVaku9U",
    "Lunges": "https://www.youtube.com/watch?v=xqvCmoLULNY",
    "Planks": "https://www.youtube.com/watch?v=pSHjTRCQxIw",
    "Burpees": "https://www.youtube.com/watch?v=TU8QYVW0gDU",
    "Mountain Climbers": "https://www.youtube.com/watch?v=nmwgirgXLYM",
    "Jumping Jacks": "https://www.youtube.com/watch?v=c4DAnQ6DtF8",
    "High Knees": "https://www.youtube.com/watch?v=OAJ_J3EZkdY",
    "Tricep Dips": "https://www.youtube.com/watch?v=89_spgcdQlw",
    "Glute Bridges": "https://www.youtube.com/watch?v=Xp33YgPZgns",
    "Bicycle Crunches": "https://www.youtube.com/watch?v=9FGilxCbdz8",
    "Leg Raises": "https://www.youtube.com/watch?v=JB2oyawG9KI",
    "Superman": "https://www.youtube.com/watch?v=cc6UVRS7PW4",
    }


    message = (
        f"Generate a 14-day workout plan, diet plan, and cheat meal plan for the user based on the following information  and be quick:\n\n"
        f"{user_info}\n"
        )
    try:
        client = OpenAI(api_key=api_key)

        response = client.beta.chat.completions.parse(
            model="gpt-4o-2024-08-06",
            messages=[
                {"role": "system", "content": "You are Leo, a highly trained fitness expert. Analyse the user information provided deeply and generate a 14-day workout plan, diet plan, and cheat meal plan. The plans should be highly user-friendly and only recommend home workouts. You can recommend at most 5 exercises per day for the workout plan. The only exercises you can recommend are push ups, squats, lunges, planks, burpees, mountain climbers, jumping jacks, high knees, tricep dips  glute bridges, bicycle crunches, leg raises and superman.\n"
                "for diet and cheat meal plans, consider the user's favorite cuisines, other restrictions, and diet percentage. The plans should be highly user-friendly and tailored to the user's preferences."
                " same for cheat meal plan, consider the user's favorite cuisines and other restrictions. The cheat meal plan should include recommended restaurants and meals. It should also be with respect to the user fitness level.\n"
                "strictly follow the format provided for each plan.\n"
                "do not take too much time to generate the plans, be quick, accurate and efficient.\n"},
                 {"role": "user", "content": message}

            ],
            response_format=AllPlans,  # structured output
        )
       
        # Parse the response
        all_plans = response.choices[0].message.parsed  # type: AllPlans

        for day_plan in all_plans.workout_plan.plan:
            # Add tutorial links to each exercise
            if day_plan.exercise_1_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_1 = EXERCISE_TUTORIALS[day_plan.exercise_1_name]
            if day_plan.exercise_2_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_2 = EXERCISE_TUTORIALS[day_plan.exercise_2_name]
            if day_plan.exercise_3_name and day_plan.exercise_3_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_3 = EXERCISE_TUTORIALS[day_plan.exercise_3_name]
            if day_plan.exercise_4_name and day_plan.exercise_4_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_4 = EXERCISE_TUTORIALS[day_plan.exercise_4_name]
            if day_plan.exercise_5_name and day_plan.exercise_5_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_5 = EXERCISE_TUTORIALS[day_plan.exercise_5_name]

       

        workout_plan_json = all_plans.workout_plan.model_dump_json()
        diet_plan_json = all_plans.diet_plan.model_dump_json()
        cheat_meal_plan_json = all_plans.cheat_meal_plan.model_dump_json()
      

        # stores the workout plan in db
        user_exist = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        if user_exist:
            user_exist.workout_plan = workout_plan_json
            user_exist.diet_plan = diet_plan_json
            user_exist.cheat_meal_plan = cheat_meal_plan_json
        else:
            new_user = FinalUserInfo(
                user_id=user_id,
                workout_plan=workout_plan_json,
                diet_plan=diet_plan_json,
                cheat_meal_plan=cheat_meal_plan_json
            )
            session.add(new_user)
        session.commit()
       
        return JSONResponse({
            "status": "success",
            "status": "success",
            "workout_plan": all_plans.workout_plan.model_dump(),
            "diet_plan": all_plans.diet_plan.model_dump(),
            "cheat_meal_plan": all_plans.cheat_meal_plan.model_dump()
        })
    except Exception as e:
        session.rollback()
     
        return JSONResponse({"status": "error", "message": str(e)})
    
    finally:
        session.close()

    

# generates the workout plan based on the user info
@app.post("/user-workout-plan-generate")
async def user_workout_plan_generate(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    user_info = await get_all_user_info_string(user_id, session)

    # backend mapping for tutorial links
    EXERCISE_TUTORIALS = {
    "Push Ups": "https://www.youtube.com/watch?v=IODxDxX7oi4",
    "Squats": "https://www.youtube.com/watch?v=aclHkVaku9U",
    "Lunges": "https://www.youtube.com/watch?v=xqvCmoLULNY",
    "Planks": "https://www.youtube.com/watch?v=pSHjTRCQxIw",
    "Burpees": "https://www.youtube.com/watch?v=TU8QYVW0gDU",
    "Mountain Climbers": "https://www.youtube.com/watch?v=nmwgirgXLYM",
    "Jumping Jacks": "https://www.youtube.com/watch?v=c4DAnQ6DtF8",
    "High Knees": "https://www.youtube.com/watch?v=OAJ_J3EZkdY",
    "Tricep Dips": "https://www.youtube.com/watch?v=89_spgcdQlw",
    "Glute Bridges": "https://www.youtube.com/watch?v=Xp33YgPZgns",
    "Bicycle Crunches": "https://www.youtube.com/watch?v=9FGilxCbdz8",
    "Leg Raises": "https://www.youtube.com/watch?v=JB2oyawG9KI",
    "Superman": "https://www.youtube.com/watch?v=cc6UVRS7PW4",
    }

    message = (
        f"Generate a 14-day workout plan for the user based on the following information:\n\n"
        f"{user_info}\n"
    )
    
    try:
        client = OpenAI(api_key=api_key)
        
        # Try the beta parse method for 1.82.0
        response = client.beta.chat.completions.parse(
            model="gpt-4o-2024-08-06",
            messages=[
                {"role": "system", "content": "You are Leo, a highly-trained fitness expert. Be friendly, motivating, and go deep in analysis. The plan is supposed to be highly user friendly. You are only supposed to recommend home workouts and no gym workouts.At most you can recommend 5 exercises. The only exercises you can recommend are push ups, squats, lunges, planks, burpees, mountain climbers, jumping jacks, high knees, tricep dips  glute bridges, bicycle crunches, leg raises and superman.\n"},
                {"role": "user", "content": message}
            ],
            response_format=WorkoutPlanList,
        )

        workout_plan_obj = response.choices[0].message.parsed
        for day_plan in workout_plan_obj.plan:
            # Add tutorial links to each exercise
            if day_plan.exercise_1_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_1 = EXERCISE_TUTORIALS[day_plan.exercise_1_name]
            if day_plan.exercise_2_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_2 = EXERCISE_TUTORIALS[day_plan.exercise_2_name]
            if day_plan.exercise_3_name and day_plan.exercise_3_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_3 = EXERCISE_TUTORIALS[day_plan.exercise_3_name]
            if day_plan.exercise_4_name and day_plan.exercise_4_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_4 = EXERCISE_TUTORIALS[day_plan.exercise_4_name]
            if day_plan.exercise_5_name and day_plan.exercise_5_name in EXERCISE_TUTORIALS:
                day_plan.tutorial_exercise_5 = EXERCISE_TUTORIALS[day_plan.exercise_5_name]

      
        workout_plan_json = workout_plan_obj.model_dump_json()

        # Save to database (same as before)
        user_workout_plan = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        if user_workout_plan:
            user_workout_plan.workout_plan = workout_plan_json
        else:
            new_workout_plan = FinalUserInfo(
                user_id=user_id,
                workout_plan=workout_plan_json
            )
            session.add(new_workout_plan)

        session.commit()
        return JSONResponse({"status": "success", "workout_plan": workout_plan_obj.model_dump()})

    except Exception as e:
        session.rollback()
        return JSONResponse({"status": "error", "message": str(e)})
    finally:
        session.close()


# generates the diet plan based on the user info
@app.post("/user-diet-plan-generate")
async def user_diet_plan_generate(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    user_info = await get_all_user_info_string(user_id, session)

    message = (
        f"Generate a 14-day diet plan for the user based on the following information:\n\n"
        f"{user_info}\n")
    
    try:
        client = OpenAI(api_key=api_key)
        response = client.beta.chat.completions.parse(
            model="gpt-4o-2024-08-06",
            messages=[
                {"role": "system", "content": "You are Leo, a highly-trained fitness expert. Who is friendly, encouraging and understand each user and goes in depth. what ever data you are provided just make sure go through it deeply and analyse "  },
                {"role": "user", "content": message}],
            response_format=DietPlanList,  # structured output
        )
        diet_plan_obj = response.choices[0].message.parsed # type: DietPlanList
        diet_plan_json = diet_plan_obj.model_dump_json()

        
        # stores the diet plan in the db and checks if the user already has a diet plan and if yes then updates it
       
        user_diet_plan = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        if user_diet_plan:
                user_diet_plan.diet_plan = diet_plan_json
        else:
                new_diet_plan = FinalUserInfo(
                    user_id=user_id,
                    diet_plan=diet_plan_json
                )
                session.add(new_diet_plan)
        session.commit()
        return JSONResponse({"status": "success", "diet_plan": diet_plan_obj.model_dump()})
    except Exception as e:
        session.rollback()
        return JSONResponse({"status": "error", "message": str(e)})
    finally:
        session.close()

# generates the cheat meal plan based on the user info
@app.post("/user-cheat-meal-plan-generate")
async def user_cheat_meal_plan_generate(request:Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    user_info = await get_all_user_info_string( user_id, session)

    message = (
        f"Generate a cheat meal plan for the user based on the following information:\n\n"
        f"{user_info}\n")
    
    try:
        client = OpenAI(api_key=api_key)
        response = client.beta.chat.completions.parse(
            model="gpt-4o-2024-08-06",
            messages=[
                {"role": "system", "content": "You are Leo, a highly-trained fitness expert. Who is friendly, encouraging and understand each user and goes in depth. what ever data you are provided just make sure go through it deeply and analyse "  },
                {"role": "user", "content": message}],
            response_format=CheatMealPlanList,  # structured output
            
        )
        cheat_meal_plan_obj = response.choices[0].message.parsed    # type: CheatMealPlanList
        cheat_meal_plan_json = cheat_meal_plan_obj.model_dump_json()
        
        # stores the cheat meal plan in the db and checks if the user already has a cheat meal plan and if yes then updates it
        
        user_cheat_meal_plan = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
        if user_cheat_meal_plan:
                user_cheat_meal_plan.cheat_meal_plan = cheat_meal_plan_json
        else:
                new_cheat_meal_plan = FinalUserInfo(
                    user_id=user_id,
                    cheat_meal_plan=cheat_meal_plan_json
                )
                session.add(new_cheat_meal_plan)
        session.commit()
        return JSONResponse({"status": "success", "cheat_meal_plan": cheat_meal_plan_obj.model_dump()})
    except Exception as e:
        session.rollback()
        return JSONResponse({"status": "error", "message": str(e)})
    finally:
        session.close()

@app.post("/chat")
async def chat(request: Request):
    session = SessionLocal()
    data = await request.json()
    user_id = data["user_id"]
    message = data["message"]
    current_time = data["datetime"]
    timezone = data["timezone"]
    # adding current date and time with every message
   
    message = f"datetime: [{current_time} and timezone: {timezone}]  {message}"
    
    user_info = await get_all_user_info_string(user_id, session)


    # Fetch last 6 chats
    n = 6
    chats = session.query(Chat).filter_by(user_id=user_id).order_by(desc(Chat.timestamp)).limit(n).all()
    previous_chats = list(reversed(chats))

    messages = []
    messages.append({
        "role": "system",
        "content": "You are Leo, a highly-trained fitness expert of Fittergem. Friendly, encouraging, and thorough. You can only speak about fitness, workouts, diet, cheat meals, and calendar events. Or fitness in general. About body, health, and nutrition. Any other topic is out of bounds and you should politely refuse to answer. "
                   "You can update workout, cheat, diet plans, and add events to Google Calendar.If the user asks to remove events then just politely refuse it saying privacy concerns and do not call any tool. If the user is asking confidential information make sure to refuse it politely. For updating the workout, cheat, or diet plans, use the respective functions and just return the JSON output of only those specific days you want to update. Again behave like an expert coach, do not just make adjustments which are unrealistic, you can suggest better ones or politely tell no if they are unrealistic and will mess up his workout and diet."
                   "for cheat meal plan, you can update the entire plan at once and return the whole JSON file as described. "
                   "you are returning very long messages, so make sure to be concise and to the point and not big. "
                   "if the user is asking to update the entire plan or to make a lot of changes, then return the entire plan in JSON format. Otherwise try to update for only specific days"
                   "Always confirm changes with the user before updating. "
                   "Always tell the user the specific details when you update any plan. Do not return any json file but just tell the user the day and the changes made"
                   " you are provided the timezone and current time in every chat so make sure you use it and if user asks back then you can tell them"
                   "do not return the youtube links to the user as well, just use them for your reference. "
                   "do not return any json file to the user, not at all. Even after any adjustments"
                   "Also consider the time the user's plans were generated and also the time message was sent and so you should know what day of diet or workout plan is and if it is past day 14 then ask to generate a new workout plan first and generate it and then ask for diet plan and if yes then do it as well"
                   "Only use JSON when triggering a tool; otherwise, speak conversationally." + user_info
    })

    for chat in previous_chats:
        if chat.input_text and chat.output_text:
            messages.append({"role": "user", "content": chat.input_text})
            messages.append({"role": "assistant", "content": chat.output_text})

    messages.append({"role": "user", "content": message})


    client = OpenAI(api_key=api_key)

    response =  client.chat.completions.create(
        model="gpt-4o-2024-08-06",
        messages=messages,
        tools=[
            openai.pydantic_function_tool(WorkoutPlanUpdate),
            openai.pydantic_function_tool(CheatMealPlanUpdate),
            openai.pydantic_function_tool(DietPlanUpdate),
            openai.pydantic_function_tool(CalendarEventAddList),
        ],
        tool_choice="auto"
    )

    choice = response.choices[0].message
    tool_calls = getattr(choice, "tool_calls", None)

    if tool_calls:
    
        tool_call = tool_calls[0]  # only one tool at a time
        tool_name = tool_call.function.name
        tool_args = json.loads(tool_call.function.arguments)

        # Store an interim GPT message for updating
        interim_message = f"Updating your {tool_name.replace('Update','').replace('CalendarEvent','calendar event').lower()}..."
        messages.append({"role": "assistant", "content": interim_message})
        session.add(Chat(user_id=user_id, input_text=message, output_text=interim_message))
        session.commit()

        # --- Process the tool call ---
        status = ""
        if tool_name in ["WorkoutPlanUpdate", "CheatMealPlanUpdate", "DietPlanUpdate"]:
            model_class = {
                "WorkoutPlanUpdate": WorkoutPlanUpdate,
                "CheatMealPlanUpdate": CheatMealPlanUpdate,
                "DietPlanUpdate": DietPlanUpdate
            }[tool_name]

            update_obj = model_class.model_validate(tool_args)
            update_json = update_obj.model_dump_json()
            user_plan = session.query(FinalUserInfo).filter_by(user_id=user_id).first()
            # ai will send json output of specific days to be updated so we need to merge it with the existing plan and only change the specific days
            # when any of the plans is updated, we need to do recrusion and start the endpoint again
            if user_plan:
                if tool_name == "WorkoutPlanUpdate":
                    workout_plan = user_plan.workout_plan
                    if workout_plan:
                        workout_plan_data = json.loads(workout_plan)
                        update_data = json.loads(update_json)
                        day_map = {day["day"]: day for day in workout_plan_data["plan"]}
                        for updated_day in update_data["plan"]:
                            day_map[updated_day["day"]] = updated_day
                        merged_plan = {"plan": list(day_map.values())}
                        user_plan.workout_plan = json.dumps(merged_plan)
                    else:
                        user_plan.workout_plan = update_json
                    
                        # update the cheat meal plan
                        # without any loop or nothing just update the whole plan with the new plan
                elif tool_name == "CheatMealPlanUpdate":
                    # updates the whole cheat meal plan at once
                      user_plan.cheat_meal_plan = update_json
                     
                    
                        
                    
                elif tool_name == "DietPlanUpdate":
                    diet_plan=user_plan.diet_plan
                    if diet_plan:
                        diet_plan_data = json.loads(diet_plan)
                        update_data = json.loads(update_json)
                        day_map = {day["day"]: day for day in diet_plan_data["plan"]}
                        for updated_day in update_data["plan"]:
                            day_map[updated_day["day"]] = updated_day
                        merged_plan = {"plan": list(day_map.values())}
                        user_plan.diet_plan = json.dumps(merged_plan)
                    else:
                        user_plan.diet_plan = update_json
                    
            else:
                new_user = FinalUserInfo(
                    user_id=user_id,
                    workout_plan=update_json if tool_name == "WorkoutPlanUpdate" else None,
                    cheat_meal_plan=update_json if tool_name == "CheatMealPlanUpdate" else None,
                    diet_plan=update_json if tool_name == "DietPlanUpdate" else None
                )
                session.add(new_user)
            session.commit()
            #we need to start the endpoint again to get the new info and last 6 messages to not run out of tokens
            
          
            status = tool_name.replace("Update","").lower() + "_updated"

        elif tool_name in ["CalendarEventAddList"]:
            calendar_events = [ 
                {
                    "summary": e["summary"],
                    "event": e["event"],
                    "time_start": e["time_start"],
                    "time_end": e["time_end"],
                    "timeZone": e["timeZone"]
                } 
                for e in tool_args["events"]
            ]
            endpoint = "Calendar-update"
            async with httpx.AsyncClient() as client:
                response = await client.post(f"https://web-production-f7f35.up.railway.app/{endpoint}?user_id={user_id}", json={"events": calendar_events})
            status = "events_added"
            if response.status_code != 200:
                return JSONResponse({
                    "status": "error",
                    "message": f"Failed to {status}: {response.text}",
                    "update_status": status
                })

        session.commit()

        # --- Ask GPT to generate a realistic confirmation ---
        if tool_name in ["WorkoutPlanUpdate", "CheatMealPlanUpdate", "DietPlanUpdate"]:
         
         messages.append({"role": "system", "content": "The last action has been successfully completed. Now generate a friendly, natural confirmation message to the user."})
         followup_response = client.chat.completions.create(
            model="gpt-4o-2024-08-06",
            messages=messages
         )
         gpt_message = followup_response.choices[0].message.content
         if not gpt_message or gpt_message.strip() == "":
            gpt_message = f"Your {status.replace('_',' ')} has been updated successfully!"

        else:
            gpt_message = "Your Google Calendar events have been successfully updated! ✅"



        session.add(Chat(user_id=user_id, input_text=message, output_text=gpt_message))
        session.commit()

        if tool_name == "WorkoutPlanUpdate":
            status = "workout_plan_updated"
        elif tool_name == "CheatMealPlanUpdate":
            status = "cheat_meal_plan_updated"
        elif tool_name == "DietPlanUpdate":
            status = "diet_plan_updated"
        elif tool_name == "CalendarEventAddList":
            status = "events_added"

        return JSONResponse({
            "status": status,
            "message": gpt_message,
        })

    else:
        # No tool call
        gpt_message = choice.content
        if not gpt_message or gpt_message.strip() == "":
            gpt_message = "I'm here to help! Could you clarify that for me?"
        session.add(Chat(user_id=user_id, input_text=message, output_text=gpt_message))
        session.commit()
        return JSONResponse({"status": "success", "message": gpt_message})

    
class FoodVerification(BaseModel):
    status: Literal["verified", "unsure", "invalid_image"] # verified or unsure or not_verified
    description: str # description of the food
     # quantity of the food
    insights: Optional[str] # insights about the food

 # encodes the image to base64

 # helper function to encode image to base64  
def encode_image(path: str) -> str:
 with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()

@app.post("/image-verify")
async def image_verify(request: Request):
    data = await request.json()
    user_id = data["user_id"]
    encoded_image = data["image"]
    datetime = data["datetime"]
    

    if not encoded_image or not datetime or not user_id:
        return JSONResponse({"status": "error", "message": "Not all required info provided"})

    client = OpenAI(api_key=api_key)
    try:
        

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a fitness expert and please review this image.\n"
                        "You should return status as verified or unsure or not_verified. "
                        "Return not_verfied or unsure when you do not see any meal at all. "
                        "Even if you see some components or something then please provide a description of the food. "
                        "Do not just simply reject that image. You can also make a guess from the image and be realistic. "
                        "Again the images will not be perfect but you need to adapt and gives us information about it."
                    )
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Verify this food image."},
                        {"type": "image_url", "image_url": {
                            "url": f"data:image/jpeg;base64,{encoded_image}"
                        }}
                    ]
                }
            ],
            tools=[openai.pydantic_function_tool(FoodVerification)]
        )

        choice = response.choices[0].message
        tool_call = getattr(choice, "tool_calls", None)
       

        if tool_call:
            tool_call = tool_call[0]
            tool_name = tool_call.function.name
            tool_args = json.loads(tool_call.function.arguments)

            if tool_name == "FoodVerification":
                status = tool_args.get("status")

                if status == "invalid_image":
                    return JSONResponse({"status": "error", "message": "Invalid image provided."})
                elif status == "unsure":
                    return JSONResponse({"status": "unsure", "message": "The image is not clear enough to verify."})
                elif status == "verified":
                    food_name = tool_args["description"]
                    insights = tool_args.get("insights", "No insights provided.")
                    message = (
                        f"The user had {food_name}. Insights: {insights}. "
                        f"Time eaten: {datetime}. Please provide your views on the meal. Be as humanly as possible and you can be funny or serious whichever one you think is needed, "
                        " Do not return a long message, keep it concise and to the point."
                        "you can make adjustments to user's diet plan or workout plan or cheal meal, but ask him first and clearly state what you want to change and then only change for specific days"
                    )
                    return JSONResponse({"status": "done", "full_prompt": message})

    except Exception as e:
    
        return JSONResponse({"status": "error", "message": str(e)})
