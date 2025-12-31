# SquadHub

**SquadHub** is a comprehensive lifestyle coordination app built with Flutter, designed to synchronize the daily lives of friend groups ("squads"). It focuses on four core pillars: availability, finance, entertainment, and safety.

## Features

### 1. Live Status & Availability
*   **Real-time status updates**: See who is Free, Busy, Studying, or Working at a glance.

### 2. SplitIt (Ledger)
*   **Expense Tracking**: Easily add shared expenses for the group.
*   **Debt Management**: Robust algorithm to track "who owes who" and "who is owed".
*   **Settle Up**: Visual indicators for settlement status.

### 3. Watchlist (Powered by TMDB)
*   **Movie Integration**: Search and add movies using real data from **The Movie Database (TMDB)**.
*   **Voting System**: Propose movies and vote with your squad.
*   **Favorites**: Keep track of your personal must-watch list.
*   **Rich Details**: View high-quality posters, backdrops, ratings, and plot overviews.

### 4. SafeWalk
*   **Live Location Sharing**: Simulate a safe journey.
*   **Guardian System**: Select a squad member to watch over your walk.
*   **Slider to Stop**: Custom "Slide to Stop" UI to prevent accidental cancellations during emergencies.

### 5. Profile
*   **Notifications**: turn on or off app notifications.
*   **Dark/Light Mode**: Customize the appearance of the application.
*   **Edit Profile**: Edit personal information after signup or login.

## Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: Bloc state management.
*   **Navigation**: Flutter Named Routes.
*   **Networking**: `dio` for Ntwork operation and `http` package for API integration.
*   **Fonts**: `google_fonts`.
*   **Safety**: `slide_action_button` custom widget.

## Getting Started

### Prerequisites
*   Flutter SDK (Latest Stable)
*   Dart SDK

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Yonatan-minlargih/SquadHub.git
    cd SquadHub
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Configure API Key**:
    *   Open `lib/core/services/movie_service.dart`.
    *   Ensure the `_apiKey` is set (Default key provided for demo purposes).

4.  **Run the app**:
    ```bash
    flutter run
    ```

## Project Structure

```
lib/
├── core/
│   ├── bloc/           # Custom State Management 
│   ├── constants/      # AppColors, TextStyles, Spacing
│   ├── mock/           # Mock data for Users, Expenses, Watchlist
│   ├── models/         # Data models
│   ├── services/       # MovieService (TMDB)
│   ├── theme/          # AppTheme (Light/Dark)
│   ├── utils/          # Includes validation utility file
│   └── widgets/        # Reusable widgets (SlideButton, StatusChip)
├── features/
│   ├── auth/           # Login & Onboarding
│   ├── chat/           # Chat Screen
│   ├── ledger/         # SplitIt Screen
│   ├── profile/        # Profile & Settings
│   ├── safewalk/       # SafeWalk Screen
│   ├── squads/         # Main Navigation Hub
│   ├── status/         # Status Screen
│   └── watchlist/      # Watchlist & Movie Details
├── routes/             # App Routes definitions
├── app.dart            # Main App Widget & Theme Setup
└── main.dart           # Entry point for the Flutter Application
```