# 🏋️ FitterGem — AI-Powered Fitness Platform

A full-stack mobile application that generates **personalized workout, diet, and cheat-meal plans in under 30 seconds** using GPT-4o, real-time health data, and location-aware recommendations.

Built with **Flutter · FastAPI · PostgreSQL · OpenAI API · Google APIs**

---

<img width="1318" height="641" alt="FitterGem Banner" src="https://github.com/user-attachments/assets/0b082b3e-7f1e-4d54-8b3e-764c707ba083" />

---

## 🚩 The Problem

Most fitness apps are static — once a plan is set, adapting it requires starting over. Users misreport food intake, forget workouts, and struggle to find meals that fit their diet on a cheat day. FitterGem solves all of this in one place.

---

## ✨ Features

**🤖 AI-Powered Personalization**
Dynamic workout, diet, and cheat-meal plans tailored to individual goals — update your preferences with a single prompt and the AI recalculates everything instantly.

**📸 Image-Based Meal Verification**
Upload a photo of your food and AI identifies the type and quantity — ensuring accurate calorie and nutrient tracking without manual input.

**📍 Location-Aware Cheat Meals**
Get the best nearby restaurant recommendations that align with your diet preferences, so cheat days don't derail your progress.

**📅 Google Calendar Integration**
Automatically schedules workouts, meal prep reminders, and check-ins with full timezone awareness.

**⌚ Health Data Sync**
Pulls real-time steps, sleep, heart rate, calories, and exercise data from Google Fit and Apple Health.

---

## 📱 Screenshots

<p align="center">
  <img width="257" height="520" alt="Onboarding" src="https://github.com/user-attachments/assets/444e393d-2d85-45ec-910e-51fa4f8d59be" />
  &nbsp;&nbsp;&nbsp;
  <img width="252" height="531" alt="Workout Plan" src="https://github.com/user-attachments/assets/ba3382ed-e6f7-4cb4-998e-fcda22aa59a1" />
  &nbsp;&nbsp;&nbsp;
  <img width="267" height="517" alt="Meal Review" src="https://github.com/user-attachments/assets/b343b010-1657-416a-9c71-993b7f6458eb" />
</p>

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Python, FastAPI, Flask |
| AI / ML | OpenAI GPT-4o, structured outputs, image verification |
| Database | PostgreSQL via SQLAlchemy |
| Health APIs | Google Fit, Apple Health |
| Scheduling | Google Calendar API, OAuth 2.0 |
| Deployment | Android (closed testing on Play Store) |

---

## 🏆 Key Technical Achievements

- **O(1) health updates** — redesigned database schema enabling instant plan regeneration without full recalculation, reducing runtime by **50%**
- **95% reduction in hallucination errors** — implemented structured JSON output validation for all GPT responses
- **Sub-30 second plan generation** — optimized prompt pipeline and async backend for fast end-to-end response times
- **Real-time health sync** — integrated wearable API pipelines with live data ingestion from Google Fit and Apple Health

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Python 3.9+
- PostgreSQL
- OpenAI API key
- Google Cloud project with Calendar & Fit APIs enabled

### Backend Setup
```bash
cd Backend
pip install -r requirements.txt
cp .env.example .env   # Add your API keys
uvicorn main:app --reload
```

### Frontend Setup
```bash
cd fittergem_frontend
flutter pub get
flutter run
```

### Environment Variables
```
OPENAI_API_KEY=your_openai_key_here
DATABASE_URL=your_postgresql_url_here
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
```

---

## 🚀 Deployment

FitterGem is currently in **closed testing on the Google Play Store**.

[▶ View Demo Video](https://lnkd.in/e2Pj-_GZ)

---

## 👨‍💻 Developer

**Aman Sharma** — CS Student @ Western University  
[LinkedIn](https://www.linkedin.com/in/aman-sharma-086310271/) · [Portfolio](https://aman-portfolio-three-xi.vercel.app/) · [GitHub](https://github.com/venom11-coder)
