# Fitness Tracker App

A comprehensive Flutter-based fitness tracking application that helps users monitor their workouts, track progress, and engage with a fitness community.

## Features

- **User Authentication**: Secure login and signup with Firebase authentication.
- **Health Dashboard**: View weekly calories, exercise minutes, workout counts, BMI, sleep hours, and more.
- **Workouts & Exercises**: Browse and complete workouts categorized by body focus, with detailed exercise tracking including reps, sets, and weight.
- **Progress Tracking**: Monitor personal records, workout history, and insights.
- **Community**: Share progress photos, posts, and interact with other users.
- **Profile Management**: Update profile picture, display name, and view progress album.
- **Future Chatbot**: AI-powered fitness assistant for personalized advice (planned feature).

## Prerequisites

- Flutter SDK (version 3.0 or higher)
- Dart SDK
- Firebase account for backend services
- Supabase account for media storage
- Android Studio or VS Code for development

## Installation

1. Clone the repository:

   ```
   git clone https://github.com/yourusername/fitness-tracker-app.git
   cd Fitness-Tracker-app
   ```

2. Install dependencies:

   ```
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project
   - Add your `google-services.json` to `android/app/`
   - Configure Firebase Authentication and Firestore

4. Set up Supabase:
   - Create a Supabase project
   - Configure storage buckets for profile pictures and community posts

5. Run the app:
   ```
   flutter run
   ```

## Usage

- Launch the app and sign up or log in.
- Complete your profile setup.
- Explore workouts, track your progress, and engage with the community.

## Project Structure

- `lib/`: Main application code
  - `screens/`: UI screens
  - `models/`: Data models
  - `services/`: Backend services
  - `widgets/`: Reusable UI components
- `assets/`: Images, videos, and other assets
- `android/`: Android-specific configuration
- `ios/`: iOS-specific configuration



