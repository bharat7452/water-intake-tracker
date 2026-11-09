# Water Intake Tracker

A Flutter mobile app that helps users build a healthy daily hydration habit. Users log the water they drink, watch their progress toward a daily goal, and review their last 7 days.

Built for the **User Interface Design using Flutter** lab (SDG Project), Department of Computer Science and Engineering, Vishnu Institute of Technology, Bhimavaram.

## SDG Relevance

| SDG | How the app helps |
|-----|-------------------|
| **SDG 3: Good Health & Well-being** | Encourages proper daily hydration, which supports digestion, concentration, kidney function and energy. |
| **SDG 6: Clean Water & Sanitation** | Builds awareness of water as a precious resource and promotes safe tap or filtered water over bottled water to reduce plastic waste. |

## Features

- **Daily progress ring** with an animated fill, amount logged, amount remaining and glass count
- **Quick add** buttons (150 ml, 250 ml, 500 ml) and a **custom amount** dialog with form validation
- **Undo** and **reset** options for today's intake
- **Streak counter** for consecutive days the goal was met
- **History tab** with an animated 7-day bar chart, daily average and days goal met
- **SDG Impact tab** explaining the project's social relevance
- **Settings screen** (named route) with an adjustable daily goal (1000 to 5000 ml)
- **Responsive layout** that adapts between phone and wide screens
- **Material 3 theme** with custom card styling

## Flutter Concepts Used

| Concept | Where |
|---------|-------|
| Widgets and layouts (Row, Column, Stack, ListView) | All screens |
| Responsive UI with `MediaQuery` | Today tab |
| Navigation with named routes | Home to Settings |
| Bottom navigation (`NavigationBar`) | Today / History / SDG Impact |
| State management with Provider (`ChangeNotifier`) | `WaterTracker` |
| Custom widgets and themes | `_ProgressRing`, `_QuickButton`, `ThemeData` |
| Forms and validation | Custom amount dialog |
| Animations | `TweenAnimationBuilder`, `AnimatedContainer`, `AnimatedSwitcher` |

## Project Structure

```
water_intake_tracker/
├── lib/
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Getting Started

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.27 or newer) and an emulator or physical device.

```bash
git clone https://github.com/<your-username>/water-intake-tracker.git
cd water-intake-tracker
flutter pub get
flutter run
```

## Tech Stack

- Flutter and Dart
- Provider (state management)

## Future Improvements

- Save data locally with `shared_preferences`
- Hydration tips fetched from a REST API
- Reminder notifications
- Dark mode

## Author

- **Name:** Puraanapanda N V Jithendra Bharadwaaja
- **Roll No:** 24PA1A05I5
- **Course:** User Interface Design using Flutter, B.Tech CSE
  
