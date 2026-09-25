# Flutter LMS

A full-stack **Learning Management System (LMS)** mobile application built with **Flutter** and a RESTful backend API.

The application supports role-based workflows for **Students, Instructors, and Administrators**, including authentication, profile management, course-related workflows, and session management.

---

## 📌 Project Overview

**Flutter LMS** is a mobile Learning Management System designed to provide a structured platform for students, instructors, and administrators.

The Flutter application communicates with a backend REST API using **Dio**, with secure authentication and role-based navigation.

### User Roles

* 👨‍🎓 **Student**
* 👨‍🏫 **Instructor**
* 🛠️ **Administrator**

Each role has its own dashboard and access permissions.

---

## 🚀 Features

### 🔐 Authentication & Account Management

* Student registration
* Instructor registration
* Login
* Logout
* Logout from all sessions
* Automatic access-token refresh
* Secure token storage
* Email verification
* Forgot password
* Password reset with OTP
* Password validation
* Role-based authentication
* Session expiration handling

### 👤 Profile Management

#### Shared User Profile

* View profile
* Update first name
* Update last name
* Update bio
* Upload profile image
* Delete profile image
* Profile image fallback handling

#### Student Profile

* Education level
* Learning goals

#### Instructor Profile

* Headline
* Qualification
* Experience
* Expertise
* Biography

### 📚 Learning Management

The LMS is designed to support:

* Course categories
* Course browsing
* Course management
* Course sections
* Lessons
* Course publishing
* Course enrollment
* Student progress
* Quizzes
* Assignments
* Reviews
* Notifications
* Student dashboards
* Instructor dashboards
* Admin LMS management

> Course-related modules are implemented progressively according to the backend API contract.

---

## 🏗️ Architecture

The project follows a clean and modular Flutter structure.

```text
lib/
├── core/
│   ├── auth/
│   │   └── auth_service.dart
│   ├── config/
│   │   └── app_config.dart
│   ├── errors/
│   │   └── api_exception.dart
│   ├── models/
│   │   └── profile/
│   │       ├── user_profile.dart
│   │       ├── student_profile.dart
│   │       ├── full_user_profile.dart
│   │       └── instructor_profile.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   └── auth_interceptor.dart
│   ├── profile/
│   │   └── profile_service.dart
│   └── storage/
│       └── token_storage.dart
│
├── screens/
│   ├── auth/
│   ├── dashboard/
│   ├── profile/
│   └── ...
│
├── widgets/
│   ├── login/
│   ├── dashboard/
│   ├── MessageWidget.dart
│   └── ...
│
├── app.dart
└── main.dart
```

### Main Architecture Concepts

* **ApiClient** → Centralized API communication using Dio
* **AuthService** → Authentication and session management
* **ProfileService** → Profile-related API operations
* **TokenStorage** → Secure token persistence
* **AuthInterceptor** → Automatic token refresh and authentication handling
* **ApiException** → Centralized API error representation
* **Models** → Strongly typed API data models
* **Screens** → Feature-specific UI screens
* **Reusable Widgets** → Shared UI components

---

## 🔑 Authentication Flow

The application uses access and refresh tokens.

```text
Login
  ↓
Access Token + Refresh Token
  ↓
Secure Storage
  ↓
API Requests
  ↓
Access Token Expired?
  ↓
Refresh Token
  ↓
Retry Original Request
```

When the refresh token is no longer valid, the application clears the session and redirects the user to the login screen.

---

## 🌐 Backend

The Flutter application communicates with the LMS backend through a REST API.

### API Base Configuration

For Android Emulator:

```text
http://10.0.2.2:5000
```

Backend API prefix:

```text
/api/v1
```

Health-check endpoint:

```text
GET /api/v1/health/ready
```

---

## 🛠️ Technology Stack

### Frontend

* Flutter 3.22.2
* Dart
* Material 3
* Provider
* Dio
* flutter_secure_storage
* image_picker
* file_picker
* mime
* http_parser

### Backend

* REST API
* Node.js backend
* MongoDB Atlas
* SMTP / Email service
* Docker

### Development Environment

* Android Studio
* Android SDK
* Android Emulator
* Java 17
* Kotlin JVM 17
* Gradle
* Git & GitHub

---

## 📦 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/RashmikaAkash/flutter_lms.git
```

### 2. Navigate to the Project

```bash
cd flutter_lms
```

### 3. Install Flutter Dependencies

```bash
flutter pub get
```

### 4. Check Connected Devices

```bash
flutter devices
```

### 5. Run the Application

```bash
flutter run
```

---

## ⚙️ Backend Setup

The mobile application expects the LMS backend to be available on:

```text
http://10.0.2.2:5000
```

when running on an Android Emulator.

Backend API prefix:

```text
/api/v1
```

Make sure the backend is running before testing authenticated API features.

---

## 🧪 Testing & Verification

Before committing changes, the project should be checked with:

```bash
flutter format .
```

```bash
flutter analyze
```

```bash
flutter test
```

For runtime verification:

```bash
flutter run
```

The application has been tested for important authentication and profile workflows including:

* Login
* Token refresh
* Logout
* Logout from all sessions
* Role-based routing
* Password recovery
* Password reset
* Profile retrieval
* Profile updates
* Profile image upload
* Profile image deletion
* Authentication failure handling

---

## 🔒 Security

The application follows several security-focused practices:

* Access and refresh tokens are stored using secure storage.
* Authentication headers are handled centrally.
* Expired access tokens are refreshed automatically when possible.
* Failed refresh attempts terminate the session.
* API errors are converted into application-level exceptions.
* Role-based API authorization is respected by the client.
* Destructive actions require user confirmation where appropriate.

---

## 👥 Role-Based Access

### Student

Students can access student-specific features such as:

* Student dashboard
* Student profile
* Learning-related workflows
* Course enrollment
* Progress tracking

### Instructor

Instructors can access instructor-specific features such as:

* Instructor dashboard
* Instructor profile
* Course management workflows

### Administrator

Administrators can access administrator-specific functionality such as:

* Admin dashboard
* User management
* LMS administration workflows

The backend remains the source of truth for authorization.

---

## 🎨 UI & Design

The application uses:

* Material 3
* Poppins typography
* Indigo-based theme
* Reusable widgets
* Separate screens for different features
* Loading, success, empty, and error states

Application logo:

```text
assets/images/logo.png
```

---

## 📂 Project Structure

```text
flutter_lms/
│
├── android/
├── assets/
│   └── images/
│       └── logo.png
│
├── lib/
│   ├── core/
│   ├── screens/
│   ├── widgets/
│   ├── app.dart
│   └── main.dart
│
├── test/
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 🔄 Development Workflow

The project is developed incrementally with the backend API contract treated as the source of truth.

Before implementing an API-driven feature:

1. Verify the backend endpoint.
2. Confirm HTTP method.
3. Confirm request parameters/body.
4. Confirm response structure.
5. Confirm authentication requirements.
6. Confirm role permissions.
7. Implement the Flutter service/model.
8. Connect the screen UI.
9. Test loading, success, empty, and error states.
10. Run formatting, analysis, tests, and runtime verification.

---

## 📈 Current Development Areas

The LMS is being developed incrementally.

Current major areas include:

* Authentication
* Session management
* Password recovery
* Profile management
* Student workflows
* Instructor workflows
* Admin workflows
* Course browsing
* Enrollment
* Curriculum
* Lessons
* Progress tracking
* Quizzes
* Assignments
* Reviews
* Notifications
* Dashboards

---

## 📌 Important Development Principle

The **backend API contract is the source of truth**.

The Flutter application should not guess:

* API endpoints
* HTTP methods
* JSON field names
* Validation rules
* Status values
* Authorization rules
* Course IDs
* User IDs
* Progress calculations

All API-driven functionality should follow the actual backend contract.

---

## 👨‍💻 Development

**Repository:**
https://github.com/RashmikaAkash/flutter_lms

**Branch:**
`main`

---

## 📄 License

This project is developed for educational and project-development purposes.
