# Mattergram — Cross-Platform Flutter Client for Mattermost

A pixel-perfect, high-performance cross-platform **Mattermost** client built with **Flutter**, designed to mirror the authentic **Telegram** user interface and user experience (UI/UX) across **Linux**, **macOS**, **Windows**, **Web**, **Android**, and **iOS**.

---

## 🌟 Features

- 🎨 **Authentic Telegram UI/UX Experience**:
  - Message bubbles with speech tails for incoming and outgoing messages.
  - Custom canvas-rendered Telegram doodle wallpaper background.
  - Message timestamps, delivery, and read receipts (`✓` sent, `✓✓` read).
  - Sticky/centered date separators dividing chat history.
  - Interactive context menus and action toolbars for emoji reactions and message management (Reply, Edit, Delete, Copy).
  - Quote reply preview banner and inline message editing banner.
  - 7 Telegram theme presets: *Telegram Dark*, *Day*, *Midnight AMOLED*, *Emerald Forest*, *Cyberpunk Violet*, *Warm Sunset*, *Arctic Frost*.
  - Telegram system sounds and haptic feedback for incoming and outgoing messages.

- 📱 **Adaptive Cross-Platform Layout**:
  - **Desktop & Web ($\ge 768$px)**: Split-screen interface with 340px sidebar, center conversation area, and collapsible right drawer panels (*Chat Info Drawer*, *Thread View*, *Hashtag Search Drawer*).
  - **Mobile ($< 768$px)**: Smooth slide navigation between Chat List and Active Conversation with back navigation.

- ⚡️ **Real-Time WebSocket Synchronization**:
  - Instant live message delivery (`posted`).
  - Real-time typing indicators in chat headers and conversation list (`user is typing...`).
  - User online/offline presence updates (`status_change`).
  - Live emoji reactions (`reaction_added`, `reaction_removed`).
  - Live message updates and deletions (`post_edited`, `post_deleted`).
  - Automatic reconnection with exponential backoff and auth challenge.

- 💬 **Thread View (CRT) & Search**:
  - Collapsible side thread panel for collapsed reply threads.
  - Hashtag drawer to search channel posts by hashtag or keyword.

- 📁 **Rich Media & File Attachments**:
  - File picker integration for document and image uploads.
  - Markdown text rendering with code blocks, bold, italic, and auto-links.
  - Full-screen interactive image lightbox with zoom and pan (`InteractiveViewer`).

- 👥 **Comprehensive Channel & Messaging Support**:
  - Public Channels, Private Groups, and Direct Messages.
  - **Saved Messages** folder with dedicated bookmark styling.
  - Category folder tabs: *All*, *Channels*, *Direct*, *Unread*.
  - Left navigation drawer menu with user profile, team switch, and settings.
  - Chat info drawer showing members list, online badges, and channel management actions (Add Members, Leave, Delete).

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.24+ recommended)
- Dart SDK (3.5+ recommended)

### Installation

```bash
git clone https://github.com/asefg482/mattergram-app.git
cd mattergram-app
flutter pub get
```

### Running the Application

```bash
# Web
flutter run -d chrome

# Linux Desktop
flutter run -d linux

# macOS Desktop
flutter run -d macos

# Windows Desktop
flutter run -d windows

# Mobile (Android / iOS)
flutter run
```

### Building for Production

```bash
# Web release
flutter build web --release

# Linux desktop release
flutter build linux --release

# Windows desktop release
flutter build windows --release

# macOS desktop release
flutter build macos --release

# Android APK / App Bundle
flutter build apk --release
flutter build appbundle --release

# iOS IPA
flutter build ipa --release
```

---

## 🧪 Testing & Analysis

```bash
flutter analyze
flutter test
```

---

## 📄 License

Open Source under MIT License.
