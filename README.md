Fittergem- Full-Stack AI Fitness Application!


<img width="1318" height="641" alt="1024x500_px" src="https://github.com/user-attachments/assets/0b082b3e-7f1e-4d54-8b3e-764c707ba083" />


Fittergem is a full-stack health and fitness app that leverages AI to provide personalized diet and workout plans. Built with Flutter (frontend), Flask (backend), and integrated with GPT-based AI, it combines smart recommendations with real-world data from Google Fit / Apple Health. 

Problems-Solved:
 Problem: Traditional fitness apps are static; once a plan is set, adapting it requires manual effort or a new plan.
Solution: Fittergem’s AI dynamically updates diet and workout plans with a single prompt. Users can change goals, preferences, or constraints, and the AI recalculates the entire plan instantly, saving time and improving personalization.

Problem: Users often misreport or misestimate their food intake, making tracking ineffective.
Solution: Users can upload food photos, and AI verifies the food type and quantity, ensuring accurate calorie and nutrient tracking.

Problem: People don't know what to eat on a cheat day which will not affect their progress.
Solution: at Fittergem, users will get get the best meals as per their diet preferences and will help towards their fitness journey, based on the nearby food places based on their location.

Problem: Users forget workouts, meal prep, or check-ins due to busy schedules.
Solution: Fittergem integrates with Google Calendar to schedule workouts, reminders, and meal events, adapting for the user’s timezone.

Features:

<img width="257" height="520" alt="ss_1" src="https://github.com/user-attachments/assets/444e393d-2d85-45ec-910e-51fa4f8d59be" />


AI-powered personalized plans: Diet, workouts, and cheat meals tailored to individual goals.

Image-based meal verification: Users can upload photos of their food; AI verifies and quantifies meals.

Google Fit / Apple Health integration: Automatically fetches steps, sleep, heart rate, calories, and exercise data.

Google Calendar integration: Automatically schedules workouts, diet reminders, and events with timezone awareness.

Comprehensive onboarding: User-friendly flow for image input, health data sync, dietary preferences, and calendar access.

Structured JSON outputs: AI generates plans in a structured format for easy parsing and future scalability.


<img width="267" height="517" alt="meal_review" src="https://github.com/user-attachments/assets/b343b010-1657-416a-9c71-993b7f6458eb" />



Tech Stack

Frontend: Flutter

Backend: Python, Flask, FastAPI

AI/ML: OpenAI GPT-4o, structured prompts, image verification

Database: PostgreSQL via SQLAlchemy

APIs & Integrations: Google Fit, Apple Health, Google Calendar



<img width="252" height="531" alt="ss_2" src="https://github.com/user-attachments/assets/ba3382ed-e6f7-4cb4-998e-fcda22aa59a1" />



Key Achievements:

Built a full-stack AI-powered application from scratch.

Implemented real-time health data sync from wearable APIs.

Developed a robust AI meal verification pipeline with fallback for user input.

Designed scalable, structured JSON prompts for consistent AI outputs.
