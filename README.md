# 🐾 PetPal – Your Pet's Personal Care Network

<div align="center">
  <p><strong>Connect. Care. Thrive.</strong></p>
  <p>The all-in-one platform connecting pet owners, veterinarians, and pet sitters for seamless pet care management.</p>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-orange?logo=firebase&logoColor=white)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-SDK-blue?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

</div>

---

## 🚀 What is PetPal?

PetPal is a modern mobile application built with **Flutter** and **Firebase** that revolutionizes pet care by bringing together three essential stakeholders:

- 🧑‍🤝‍🧑 **Pet Owners** – Manage your furry friends' health, bookings, and activities all in one place
- 🏥 **Veterinarians** – Connect with pet owners, manage appointments, and provide quality care
- 🐕 **Pet Sitters** – Build your reputation, get bookings, and care for pets in their owners' absence

> _Empowering pet care through technology – because your pet deserves the best!_

---

## ✨ Key Features

### 🔐 **Smart Authentication**

- Role-based login (Pet Owner, Vet, Pet Sitter)
- Secure password management
- Forgot password recovery with Cloud Functions

### 🐴 **Pet Management**

- Add, edit, and manage multiple pets
- Detailed pet profiles with photos
- Activity history and health tracking
- Share pet information with caregivers

### 📅 **Booking & Scheduling**

- Browse & book veterinarians and pet sitters
- Real-time booking status updates
- Automated push notifications for confirmation
- Booking history and summary

### 📊 **Health Reports & Analytics**

- Track daily activities and health metrics
- Generate comprehensive pet health reports
- Export to PDF for vet visits
- Share reports with other caregivers

### 🔔 **Smart Notifications**

- Firebase Cloud Messaging integration
- Local reminders for appointments
- Real-time updates on booking status

### 📱 **Professional Profile Management**

- Showcase credentials (for Vets & Sitters)
- Upload profile photos to Firebase Storage
- Rating and review system
- Service management

---

## 🛠️ Tech Stack

| Layer                  | Technology                                           |
| ---------------------- | ---------------------------------------------------- |
| **Frontend Framework** | Flutter 3.x with Material 3 Design                   |
| **State Management**   | BLoC Pattern with flutter_bloc                       |
| **Backend**            | Firebase (Auth, Firestore, Storage, Cloud Messaging) |
| **Cloud Functions**    | Node.js 18 with TypeScript                           |
| **Local Storage**      | Shared Preferences                                   |
| **Reports**            | PDF generation & Printing                            |
| **Notifications**      | Firebase Messaging + Local Notifications             |
| **UI Libraries**       | Google Fonts, SVG Support, Tables & Calendars        |

---

## 📁 Project Structure

```
petpal_app/
├── lib/
│   ├── blocs/                 # BLoC state management (auth, pets, bookings, reports)
│   ├── models/                # Data models (User, Pet, Booking, Activity)
│   ├── repositories/          # Data access layer
│   ├── services/              # Firebase wrappers & business logic
│   ├── screens/               # UI screens organized by feature
│   │   ├── auth/              # Login, Register, Password Recovery
│   │   ├── home/              # Dashboard & main navigation
│   │   ├── pets/              # Pet management
│   │   ├── vets/              # Veterinarian browsing & booking
│   │   ├── sitters/           # Pet sitter browsing & booking
│   │   ├── bookings/          # Booking history & management
│   │   ├── hotel/             # Pet hotel/boarding feature
│   │   ├── reports/           # Health reports & analytics
│   │   └── profile/           # User profile management
│   ├── widgets/               # Reusable UI components
│   ├── utils/                 # Constants, validators, helpers
│   └── main.dart              # App entry point
├── functions/                 # Cloud Functions (TypeScript/Node.js)
├── android/                   # Android native code
├── ios/                       # iOS native code
├── web/                       # Web support (optional)
└── pubspec.yaml               # Flutter dependencies
```

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Firebase CLI for Cloud Functions
- Android Studio / Xcode for mobile builds
- A Firebase Project configured

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/ammaribrahim95/MobileApp_PetPal.git
   cd MobileApp_PetPal/petpal_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   ```bash
   flutterfire configure
   ```

   This generates `lib/firebase_options.dart` with your Firebase credentials.

4. **Deploy Cloud Functions** (optional but recommended)

   ```bash
   cd ../functions
   npm install
   npm run build
   firebase deploy --only functions
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📱 Supported Platforms

- ✅ **Android** (API 33+)
- ✅ **iOS** (14.0+)
- ✅ **Windows** (with Developer Mode)
- ✅ **Web** (experimental)

---

## 🔧 Firebase Setup

1. Create a project on [Firebase Console](https://console.firebase.google.com)
2. Enable these services:
   - Authentication (Email/Password)
   - Firestore Database
   - Cloud Storage
   - Cloud Messaging
   - Cloud Functions
   - (Optional) App Check & Crashlytics

3. Update Firebase credentials in `lib/firebase_options.dart`

---

## 🧪 Testing

Run unit and widget tests:

```bash
flutter test
```

The project includes:

- `bloc_test` for BLoC testing
- `mocktail` for mocking dependencies

---

## 📖 Documentation

- [Setup Guide](petpal_app/SETUP_GUIDE.md) – Comprehensive setup instructions
- [Fixes Applied](petpal_app/FIXES_APPLIED.md) – List of applied fixes & improvements
- [App README](petpal_app/README.md) – Technical architecture details

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

---

## 🙋‍♀️ Support

Need help? Have questions?

- Open an [issue](https://github.com/ammaribrahim95/MobileApp_PetPal/issues)
- Check existing documentation in the `petpal_app/` folder

---

## 🌟 Roadmap

- [ ] Advanced search and filtering
- [ ] In-app chat/messaging
- [ ] Payment integration
- [ ] Vet appointment reminders
- [ ] Pet vaccination tracking
- [ ] Multi-language support
- [ ] Dark mode theme

---

<div align="center">
  <p><strong>Made with ❤️ for pet lovers everywhere</strong></p>
  <p>Give us a ⭐ if you find this project helpful!</p>
</div>
