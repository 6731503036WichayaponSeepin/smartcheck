
---

## Main Components

### main.dart

The entry point of the application.  
This file initializes Firebase and launches the main application.

Responsibilities:
- Initialize Firebase
- Configure application routes
- Start the Flutter app

---

### Login Page

File: `login_page.dart`

This screen allows students to log in using Firebase Authentication.

Features:
- Email and password login
- Google sign-in (optional)
- Authentication validation

Purpose:
Ensure that each attendance record is linked to a verified student identity.

---

### Home Page

File: `home_page.dart`

This is the main screen of the application after login.

Features:
- Navigate to **Check-in**
- Navigate to **Finish Class**
- Display basic user information

---

### Check-in Page

File: `checkin_page.dart`

This page allows students to check in before class.

Features:
- Retrieve GPS location using the **Geolocator** package
- Scan QR code using **Mobile Scanner**
- Input form for:
  - Previous class topic
  - Expected topic
  - Mood before class

Data is stored in **Firebase Firestore** after submission.

---

### Finish Class Page

File: `finish_class_page.dart`

This page allows students to complete the class session.

Features:
- Scan QR code
- Retrieve GPS location
- Input learning reflection
- Submit feedback

Data is stored in Firebase Firestore.

---

## Services

### Location Service

File: `location_service.dart`

Handles GPS location retrieval using the **Geolocator** package.

Functions:
- Request location permission
- Get current latitude and longitude

---

### QR Scanner Service

File: `qr_service.dart`

Handles QR code scanning using the **Mobile Scanner** package.

Functions:
- Activate camera
- Scan QR code
- Return scanned data

---

### Firebase Service

File: `firebase_service.dart`

Handles communication with Firebase.

Functions:
- Save attendance data to Firestore
- Retrieve user information
- Manage authentication state

---

## Data Model

File: `attendance_model.dart`

Represents attendance data stored in Firestore.

Example fields:

- userId
- checkInTime
- latitude
- longitude
- previousTopic
- expectedTopic
- moodScore
- finishTime
- learnedToday
- feedback

---

## Firebase Integration

The application integrates with Firebase for backend services.

Services used:

- **Firebase Authentication**
  - Manage user login

- **Cloud Firestore**
  - Store attendance records

- **Firebase Hosting**
  - Deploy Flutter Web version

---

## Libraries Used

The following Flutter packages are used in the project:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `geolocator`
- `mobile_scanner`

These libraries support authentication, data storage, location tracking, and QR code scanning.

---

## Summary

This application demonstrates a simple attendance verification system using modern mobile technologies.

The system combines:

- User authentication
- GPS location verification
- QR code scanning
- Learning reflection

to provide a prototype solution for classroom attendance and student engagement.