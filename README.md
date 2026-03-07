<div align="center">

<br/>

```
██████╗  █████╗ ██╗██╗     ███████╗ ██████╗  ██████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██║██║     ██╔════╝██╔═══██╗██╔════╝██║   ██║██╔════╝
██████╔╝███████║██║██║     █████╗  ██║   ██║██║     ██║   ██║███████╗
██╔══██╗██╔══██║██║██║     ██╔══╝  ██║   ██║██║     ██║   ██║╚════██║
██║  ██║██║  ██║██║███████╗██║     ╚██████╔╝╚██████╗╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝      ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝
```

**A premium, train-journey-themed focus & productivity timer.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Hive](https://img.shields.io/badge/Hive-Local%20Storage-yellow?style=for-the-badge)](https://pub.dev/packages/hive)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](./LICENSE)

*Step into the Grand Station. Punch your golden ticket. Embark on a journey of deep, uninterrupted work.*

</div>

---

## 🚉 What is RailFocus?

RailFocus is not just another Pomodoro timer — it's an **immersive productivity experience** built around the romance of golden-age rail travel. Every focus session is a train journey. Every completed hour builds your Grand Station. Every streak unlocks something beautiful.

Built with **Flutter** for a smooth cross-platform experience, **Firebase** for real-time cloud sync, and **Hive** for a rock-solid offline-first foundation.

---

## ✨ Features

### 🌅 Dynamic Scenery
A stunning art-deco diorama that shifts automatically with your **real-world time of day** — morning sunrises, twilight fireflies, midnight shooting stars, and the mesmerising aurora borealis. Your backdrop evolves as the hours do.

### ⏱️ Deep Work Timer
A fully customisable focus timer styled as a train journey. Depart, travel, and arrive at your destination — distraction-free and on schedule.

### 🏆 Gamification & Progression
- 🏗️ **Build your Grand Station** brick by brick as you complete focus sessions
- 🔥 **Daily streaks** unlock beautiful *Focus Moods* — golden hour glows, sparkle overlays, and more
- 📋 **Daily Challenges** for bonus rewards
- 🗺️ **Scenic Routes** *(The Midnight Express, Dawn Departure, and more)* unlocked by accumulating focus hours

### 🤝 Co-working Cabins
Start or join **real-time focus rooms** and work alongside friends with perfectly synced timers. Your own private cabin on the express, open to the world.

### 🎵 Ambient Sound
The focus timer currently ships with **one carefully chosen ambient track** to keep you in the zone during your journey. More soundscapes are planned for future updates.

### ☁️ Cloud Sync + Offline First
All focus hours, achievements, and progress sync seamlessly across devices via **Firebase**. A robust offline-first architecture via **Hive** ensures you never lose a session — even without a connection.

### 💎 Stunning UI/UX
Glassmorphism · Spring physics · Haptic feedback · Custom vector graphics · Micro-animations — every interaction is crafted to feel premium and satisfying.

---

## 📸 Screenshots

<div align="center">

| <img src="https://github.com/user-attachments/assets/c671acdd-6a0d-4969-8564-7396ab06f388" width="250"/> | <img src="https://github.com/user-attachments/assets/cdea9c55-c17c-4ffd-aca8-c3d156dcf6b7" width="250"/> |
|:---:|:---:|
| **The Departure Hall** | **Active Focus Journey** |

</div>

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **State Management** | Pure `StatefulWidget` + Singleton Services |
| **Cloud Backend** | Firebase Auth + Cloud Firestore |
| **Local Storage** | Hive (offline-first NoSQL) |
| **Routing** | `go_router` |
| **Animations** | `flutter_animate` + Custom Painters |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **v3.7.0+**
- Dart SDK **v3.1.0+**
- Android Studio or Xcode *(for emulation and builds)*

### Installation

**1. Clone the repository**
```sh
git clone https://github.com/andlivshukla539/RailFocus.git
cd RailFocus
```

**2. Setup Firebase**

> ⚠️ **Important:** You need to create your own Firebase project. Never commit `google-services.json` or `GoogleService-Info.plist` to version control.

- Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project
- Add an **Android** app (package name: `com.example.railfocus`) and an **iOS** app
- Enable **Authentication** → Google & Email/Password providers
- Enable **Cloud Firestore**
- Download and place the config files:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

**3. Install dependencies**
```sh
flutter pub get
```

**4. Run the app**
```sh
flutter run
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

1. Fork the project
2. Create your feature branch: `git checkout -b feature/AmazingFeature`
3. Commit your changes: `git commit -m 'Add some AmazingFeature'`
4. Push to the branch: `git push origin feature/AmazingFeature`
5. Open a Pull Request

---

## 📝 License

Distributed under the **MIT License**. See [`LICENSE`](./LICENSE) for more information.

---

<div align="center">

Made with ❤️ for focused minds.

*All aboard. 🚂*

</div>
