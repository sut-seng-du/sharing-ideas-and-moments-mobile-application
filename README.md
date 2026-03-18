# Sharing Ideas and Moments (SIM)

[![Platform: Mobile](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-91A6FF.svg)](#)
[![Flutter Version](https://img.shields.io/badge/Flutter-%5E3.11.0-blue.svg)](https://flutter.dev)

**Sharing Ideas and Moments (SIM)** is a modern, tactile mobile application designed for personal expression and memory keeping. Built with Flutter, it features a unique **Claymorphism** design aesthetic that provides a soft, 3D interactive experience.

---

## 🎨 Design Philosophy: Claymorphism

SIM stands out with its **Claymorphism** UI—a blend of soft shadows, rounded corners, and pastel colors (like our signature `#91A6FF` blue). This design choice makes the digital interface feel physical and approachable, encouraging users to interact with their "moments."

## 📱 Screenshots

<div align="center">
  <h3>Home & Features</h3>
  <img src="assets/screenshots/homescreen_with_cards.jpg" width="200" alt="Home Screen with Moments">
  <img src="assets/screenshots/new_moment_with_images.jpg" width="200" alt="Create New Moment">
  <img src="assets/screenshots/moment_detail.jpg" width="200" alt="Moment Details">
  <br>
  <i>Showcasing the soft Claymorphism UI and multimedia support.</i>
</div>

<br>

<div align="center">
  <h3>Empty States</h3>
  <img src="assets/screenshots/homescreen_empty.jpg" width="200" alt="Empty Home Screen">
  <img src="assets/screenshots/new_moment_empty.jpg" width="200" alt="New Moment Input">
</div>

## ✨ Key Features

- 📝 **Capture Moments**: Create title-based posts with rich content.
- 🖼️ **Multimedia Support**: Attach multiple images to your memories.
- 📂 **Categorization**: Organize your thoughts with custom categories.
- 🔍 **Smart Search**: Quickly find past moments using the built-in search functionality.
- 📤 **Social Sharing**: Share your curated ideas and moments with friends via system sharing.
- 🔒 **Local Storage**: All data is stored securely on-device using `sqflite`, ensuring your privacy.

## 🛠️ Technical Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Database**: [sqflite](https://pub.dev/packages/sqflite) for high-performance local persistence.
- **UI Components**: Custom `ClayContainer` for the signature 3D effect.
- **Utilities**:
  - `image_picker` for camera and gallery access.
  - `share_plus` for native sharing capabilities.
  - `intl` for clean date and time formatting.

## 🚀 Getting Started

This project is optimized for **Mobile platforms (Android and iOS)**.

### Prerequisites

- Flutter SDK (>= 3.11.0)
- Android Studio / VS Code with Flutter extension
- An Android Emulator or iOS Simulator

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/sut-seng-du/sharing-ideas-and-moments-mobile-application.git
    cd sharing-ideas-and-moments-mobile-application
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```

---

## 📱 Platform Support

- ✅ **Android**: Fully supported and tested.
- ✅ **iOS**: Fully supported and tested.
- ❌ **Web/Desktop**: These platforms have been intentionally removed to keep the mobile experience lightweight and focused.

---

## 📄 License

This project is private and for internal use.
