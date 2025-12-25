# SpanishStep App

A comprehensive Spanish vocabulary learning app with 5,000 words from DELE A1 to B2 levels.

## Features

- **5,000 Spanish Words**: Complete vocabulary from A1 (beginner) to B2 (upper-intermediate)
- **6 Languages**: Translations in English, Korean, Japanese, Chinese, Portuguese, and French
- **Daily Learning**: 30 free words per day to encourage consistent learning
- **Ad-Supported Unlock**: Watch a rewarded ad to unlock unlimited access until midnight
- **Progress Tracking**: Your learning progress is saved automatically
- **Dark Mode**: Easy on the eyes with dark mode support
- **Scroll Position Memory**: Resume exactly where you left off

## Level Distribution

| Level | Words | Description |
|-------|-------|-------------|
| A1 | 600 | Basic vocabulary for beginners |
| A2 | 600 | Elementary vocabulary |
| B1 | 1,300 | Intermediate vocabulary |
| B2 | 2,500 | Upper-intermediate vocabulary |

## Tech Stack

- Flutter 3.x
- Provider for state management
- SharedPreferences for local storage
- Google Mobile Ads SDK
- In-App Purchase for remove ads

## Setup

1. Install Flutter SDK
2. Clone this repository
3. Run `flutter pub get`
4. Run `flutter run`

## Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Configuration

### AdMob IDs
- Android App ID: `ca-app-pub-5837885590326347~6881979753`
- iOS App ID: `ca-app-pub-5837885590326347~5568898085`

### In-App Purchase
- Product ID: `com.spanishstep.app.removeads` ($1.99)

## License

MIT License
