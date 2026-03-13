# SmartCheck – Smart Class Check-in & Learning Reflection App

SmartCheck is a Flutter-based web application designed to simplify classroom attendance and learning reflection. Students can check in to class using QR codes and location verification while instructors can monitor attendance records.

---

## Live Application

Firebase Hosting URL:

https://smartcheck999.web.app

---

## GitHub Repository

https://github.com/6731503036WichayaponSeepin/smartcheck

---

## Features

- User registration and login using Firebase Authentication
- QR code scanning for classroom check-in
- GPS location verification
- Automatic attendance record storage
- Learning reflection after class
- Instructor QR code generator
- Real-time data storage using Firebase Firestore

---

## Technology Stack

Frontend
- Flutter Web
- Dart

Backend
- Firebase Authentication
- Cloud Firestore
- Firebase Hosting

---

## Application Pages

- Login Page
- Register Page
- Home Page
- Check-in Page
- Finish Class Page
- Instructor QR Page

---

## System Workflow

1. Student registers an account
2. Student logs into the system
3. Instructor generates a QR code
4. Student scans the QR code to check in
5. System verifies student location
6. Attendance record is stored in Firestore
7. Student submits learning reflection
8. Instructor can review attendance records

---

## Data Structure

### Collection: users

- uid
- email
- displayName
- createdAt

### Collection: attendanceRecords

- studentId
- sessionCode
- checkInAt
- checkInLat
- checkInLng
- finishAt
- learnedToday
- feedback
- updatedAt

---

## Deployment

This application is deployed using Firebase Hosting.

Hosting URL:
https://smartcheck999.web.app

---

## Author

Wichayapon Seepin  
Mae Fah Luang University