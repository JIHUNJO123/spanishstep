# Spanish Step - App Feature Specification

## 📱 Core Features

### 1. Daily Word Limit System

```
┌─────────────────────────────────────────────────────────────┐
│                    DAILY ACCESS MODEL                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   User Progress: Word #50                                    │
│   Daily Limit: 30 words                                      │
│                                                              │
│   ┌─────────┬─────────────────────┬─────────────────────┐   │
│   │ 🔒 LOCKED │   🔓 UNLOCKED       │     🔒 LOCKED       │   │
│   │ Words    │   Words 50-79       │     Words 80+       │   │
│   │ 1-49     │   (30 words)        │     (Future)        │   │
│   └─────────┴─────────────────────┴─────────────────────┘   │
│                                                              │
│   ← Already learned        Today's words →     Not yet →    │
│     (locked behind)        (accessible)        (locked)     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 2. Word Access Rules

| Scenario | Behavior |
|----------|----------|
| User at word #50 | Can view words 50-79 (30 words) |
| User closes app at word #65 | Next session starts at word #65 |
| User tries to go back to word #40 | 🔒 LOCKED - "Already learned" |
| User tries to skip to word #100 | 🔒 LOCKED - "Watch ad to unlock" |
| User watches rewarded ad | 🔓 Unlocks ALL words until midnight |
| User purchases Remove Ads ($1.99) | 🔓 Permanent unlimited access |

### 3. Scroll Position Persistence

```dart
// Save scroll position when leaving
void saveScrollPosition(int currentWordIndex, double scrollOffset) {
  SharedPreferences.setInt('lastWordIndex', currentWordIndex);
  SharedPreferences.setDouble('scrollOffset', scrollOffset);
}

// Restore scroll position when returning
Future<void> restoreScrollPosition() async {
  int lastIndex = SharedPreferences.getInt('lastWordIndex') ?? 0;
  double offset = SharedPreferences.getDouble('scrollOffset') ?? 0.0;
  scrollController.jumpTo(offset);
}
```

### 4. Daily Progress Tracking

```dart
class UserProgress {
  int currentWordId;        // Current position (e.g., 50)
  DateTime lastStudyDate;   // Last study date
  bool isAdUnlocked;        // Rewarded ad watched today?
  DateTime? adUnlockExpiry; // Midnight of current day
  bool isPremium;           // Purchased Remove Ads?
}
```

### 5. Lock/Unlock Logic

```dart
bool canAccessWord(int wordId, UserProgress progress) {
  // Premium users: unlimited access
  if (progress.isPremium) return true;
  
  // Ad unlock active until midnight
  if (progress.isAdUnlocked && DateTime.now().isBefore(progress.adUnlockExpiry)) {
    return true;
  }
  
  // Free user: only 30 words from current position
  int startWord = progress.currentWordId;
  int endWord = startWord + 29;
  
  return wordId >= startWord && wordId <= endWord;
}

String getLockReason(int wordId, UserProgress progress) {
  if (wordId < progress.currentWordId) {
    return "already_learned"; // 이미 학습한 단어
  } else {
    return "not_yet_unlocked"; // 아직 잠긴 단어
  }
}
```

---

## 🔐 Lock Screen UI

### When accessing locked word (behind):
```
┌────────────────────────────┐
│                            │
│      🔒 Already Learned    │
│                            │
│   This word is part of     │
│   your completed lessons.  │
│                            │
│   [Watch Ad to Review]     │
│                            │
└────────────────────────────┘
```

### When accessing locked word (ahead):
```
┌────────────────────────────┐
│                            │
│      🔒 Locked             │
│                            │
│   Complete today's words   │
│   to unlock more!          │
│                            │
│   [Watch Ad to Unlock]     │
│   [Upgrade to Premium]     │
│                            │
└────────────────────────────┘
```

---

## 📊 Data Storage (SharedPreferences)

| Key | Type | Description |
|-----|------|-------------|
| `currentWordId` | int | Current word position |
| `scrollOffset` | double | Last scroll position |
| `lastStudyDate` | String | ISO date of last study |
| `adUnlockExpiry` | String | Midnight timestamp when ad unlock expires |
| `isPremium` | bool | Remove Ads purchased |
| `levelProgress` | Map | Progress per level {A1: 150, A2: 0, ...} |

---

## ⏰ Midnight Reset Logic

```dart
DateTime getMidnight() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
}

void onRewardedAdWatched() {
  progress.isAdUnlocked = true;
  progress.adUnlockExpiry = getMidnight();
  saveProgress();
}

void checkDailyReset() {
  final now = DateTime.now();
  final lastDate = DateTime.parse(progress.lastStudyDate);
  
  if (now.day != lastDate.day) {
    // New day - reset ad unlock, keep word position
    progress.isAdUnlocked = false;
    progress.adUnlockExpiry = null;
    progress.lastStudyDate = now.toIso8601String();
    saveProgress();
  }
}
```

---

## 📺 AdMob Integration

### Rewarded Ad Flow
```
User hits daily limit (30 words)
         │
         ▼
┌─────────────────────────┐
│   Daily Limit Reached   │
│                         │
│  You've studied 30      │
│  words today! 🎉        │
│                         │
│  [Watch Ad to Continue] │
│  [Upgrade - $1.99]      │
└─────────────────────────┘
         │
         ▼ (watches ad)
┌─────────────────────────┐
│   🔓 Unlocked!          │
│                         │
│  Unlimited access       │
│  until midnight         │
└─────────────────────────┘
```

### AdMob IDs

| Platform | Type | ID |
|----------|------|-----|
| Android | App ID | `ca-app-pub-5837885590326347~6881979753` |
| Android | Rewarded | `ca-app-pub-5837885590326347/2170377421` |
| iOS | App ID | `ca-app-pub-5837885590326347~5568898085` |
| iOS | Rewarded | `ca-app-pub-5837885590326347/5713859000` |

---

## 🛒 In-App Purchase

| Product ID | Price | Effect |
|------------|-------|--------|
| `com.spanishstep.app.removeads` | $1.99 | Remove all ads + Unlimited access forever |

---

## 📱 User Flow Example

```
Day 1:
  - User opens app, starts at word #1
  - Studies words 1-30 (daily limit)
  - Hits limit at word #31 → Lock screen
  - Watches rewarded ad → Unlocked until midnight
  - Studies until word #50, closes app
  
Day 2:
  - User opens app
  - Ad unlock expired (new day)
  - Current position: word #50
  - Accessible: words 50-79 (30 words)
  - Words 1-49: LOCKED (already learned)
  - Words 80+: LOCKED (not yet)
  
Day 2 (after ad):
  - User watches rewarded ad
  - ALL words unlocked until midnight
  - Can review 1-49 or skip ahead
```

---

*Last Updated: December 25, 2025*
