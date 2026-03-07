# 🚂 RailFocus

> A premium, train-journey-themed focus and productivity timer built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Firebase](https://img.shields.io/badge/firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black) ![Hive](https://img.shields.io/badge/Hive-Local_Storage-green?style=for-the-badge)

RailFocus is not just a Pomodoro app; it's an immersive experience. Step into the beautifully crafted Grand Station, punch your golden ticket, and embark on a journey of deep work. 

## ✨ Key Features

*   **🌅 Dynamic Scenery:** Experience a stunning art-deco diorama that changes automatically based on your real-world time of day. Morning sunrise, twilight fireflies, midnight shooting stars, and the mesmerizing aurora borealis.
*   **⏱️ Deep Work Timer:** Fully customizable focus timer acting as your train journey. Arrive at your destination safely without distractions.
*   **🏆 Gamification & Progression:**
    *   Build up your own **Grand Station** brick by brick as you complete focus sessions.
    *   Earn daily streaks to unlock beautiful "Focus Moods" (e.g., golden hour glows and sparkles).
    *   Complete **Daily Challenges** for bonus rewards.
    *   Unlock gorgeous, hand-crafted scenic routes (The Midnight Express, Dawn Departure, etc.) by accumulating focus hours.
*   **🤝 Co-working Cabins:** Start or join real-time focus rooms. Study and work alongside your friends with syncing timers.
*   **🎵 Ambient Soundscapes:** Built-in audio mixer with high-quality ambient sounds (Rain, Tracks, Lo-Fi, Sleep) to keep you perfectly zoned in.
*   **☁️ Cloud Sync & Auth:** Seamlessly switch devices using Email or Google Sign-In. All your data, achievements, and focus hours securely sync via Firebase—even while supporting a robust offline-first architecture via Hive.
*   **💎 Stunning UI/UX:** Meticulously designed interfaces with glassmorphism, micro-animations, physical spring physics, haptic feedback, and custom vector graphics to ensure an incredibly satisfying experience.

---

## 📸 Screenshots

*(Replace these with actual screenshots or GIFs below)*

|<img src="" width="250"/>|<img src="" width="250"/>|<img src="" width="250"/>|
|:---:|:---:|:---:|
| **The Departure Hall** | **Cabin Selection** | **Active Focus Journey** |

---

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   Flutter SDK (v3.7.0 or higher)
*   Dart SDK (v3.1.0 or higher)
*   Android Studio / Xcode (for emulation/building)

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/your-username/RailFocus.git
   cd RailFocus
   ```

2. **Setup Firebase:**
   > **Note:** Due to security reasons, you will need to create your own Firebase project to build and test this locally with sync.
   * Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
   * Add an Android app (with the matching package name, e.g., `com.example.railfocus`) and an iOS app.
   * Download the `google-services.json` and place it in the `android/app/` directory.
   * Download the `GoogleService-Info.plist` and place it in the `ios/Runner/` directory.
   * Enable **Authentication** (Google & Email/Password) and **Firestore Database** in your Firebase project.

3. **Install dependencies:**
   ```sh
   flutter pub get
   ```

4. **Run the app:**
   Select your emulator/device and run:
   ```sh
   flutter run
   ```

---

## 🛠 Tech Stack & Architecture

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **State Management:** Pure `StatefulWidget` mechanics with isolated services (Singletons) for high performance.
*   **Backend & DB:** Firebase (Auth, Firestore) for cloud sync.
*   **Local DB:** [Hive](https://pub.dev/packages/hive) (Extremely fast, offline-first local NoSQL).
*   **Routing:** `go_router`
*   **Animations:** `flutter_animate` & built-in CustomPainters.

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">Made with ❤️ for focused minds.</p>
