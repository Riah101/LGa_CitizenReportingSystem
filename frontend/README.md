# Sauti ya Raia — Citizen Complaint & Escalation Platform
### Jukwaa la Malalamiko ya Raia

A cross-platform Flutter application that allows Tanzanian citizens to submit complaints from the Mtaa (street) level, with automatic escalation through the government hierarchy if not addressed within set timeframes.

---

## 📁 Full Project Structure

```
lib/
├── main.dart                          # App entry point
├── l10n/
│   └── app_localizations.dart         # EN + SW translations (100+ strings)
├── models/
│   ├── complaint.dart                 # Complaint model + escalation logic
│   └── user.dart                      # User model + roles
├── providers/
│   ├── auth_provider.dart             # Auth + Locale + Theme providers
│   ├── complaint_provider.dart        # Complaint state + auto-escalation
│   ├── locale_provider.dart           # Re-exports
│   └── theme_provider.dart            # Re-exports
├── screens/
│   ├── splash_screen.dart             # Animated splash
│   ├── auth/
│   │   ├── login_screen.dart          # Phone + password login
│   │   └── register_screen.dart       # Multi-step registration
│   ├── dashboard/
│   │   ├── home_screen.dart           # Bottom nav shell
│   │   ├── dashboard_screen.dart      # Citizen home with stats
│   │   ├── officer_dashboard_screen.dart  # Officer management view
│   │   ├── notifications_screen.dart  # Escalation & activity alerts
│   │   └── profile_screen.dart        # Settings + language toggle
│   └── complaints/
│       ├── submit_complaint_screen.dart   # 3-step complaint form
│       ├── complaints_list_screen.dart    # Tabbed list with search
│       ├── complaint_detail_screen.dart   # Full detail + comments
│       └── track_screen.dart             # Track by code
├── widgets/
│   ├── complaint_card.dart            # Reusable complaint list item
│   ├── escalation_timeline.dart       # Visual level progress tracker
│   ├── status_badge.dart              # Colored status indicators
│   └── stat_card.dart                 # Dashboard stat tiles
├── services/
│   └── escalation_service.dart        # Escalation rules & schedule
└── utils/
    ├── app_theme.dart                  # Full Material 3 theme
    ├── app_utils.dart                  # Helpers + constants
    └── tanzania_locations.dart         # Region → District → Ward data
```

---

## ⚙️ Escalation Rules

| Level     | Days Before Escalation | Escalates To |
|-----------|------------------------|--------------|
| Mtaa      | **7 days**             | Ward (Kata)  |
| Ward      | **14 days**            | District     |
| District  | **21 days**            | Region       |
| Region    | **30 days**            | National     |
| National  | Final — no escalation  | —            |

Auto-escalation runs on every app launch and pull-to-refresh.

---

## 🌍 Languages

| Feature        | English | Kiswahili |
|----------------|---------|-----------|
| UI labels      | ✅      | ✅        |
| Status messages| ✅      | ✅        |
| Error messages | ✅      | ✅        |
| Categories     | ✅      | ✅        |
| Level names    | ✅      | ✅        |

Language is togglable from the login screen and profile settings.

---

## 👥 User Roles

| Role            | Access                                    |
|-----------------|-------------------------------------------|
| Citizen (Raia)  | Submit, track, comment, upvote            |
| Mtaa Officer    | See Mtaa complaints, update status        |
| Ward Officer    | See Ward complaints, escalate/resolve     |
| District Officer| See District complaints                   |
| Region Officer  | See Regional complaints                   |
| National Officer| See all complaints nationally             |
| Admin           | Full access                               |

---

## 🚀 Getting Started

```bash
# Install Flutter (https://flutter.dev)
flutter pub get
flutter run

# For specific platform
flutter run -d android
flutter run -d ios
flutter run -d chrome  # Web
```

---

## 🔌 Production Integration Checklist

- [ ] **Backend API** — Connect to REST/GraphQL (replace SharedPreferences with HTTP)
- [ ] **Firebase Auth** — Replace demo auth with OTP phone verification
- [ ] **FCM Push Notifications** — Alert citizens when escalations happen
- [ ] **Firebase Cloud Functions** — Server-side cron for auto-escalation at midnight
- [ ] **Cloud Storage** — Photo/document attachments (replace local paths)
- [ ] **Location Services** — GPS auto-fill for Mtaa/Ward fields
- [ ] **Analytics** — Track complaint resolution rates per district
- [ ] **Offline Mode** — Queue submissions when no connectivity
- [ ] **Admin Portal** — Web dashboard for national-level overview

---

## 📱 Screens Overview

1. **Splash** — Animated logo with Tanzania flag accent
2. **Login** — Phone + password, language toggle
3. **Register** — 3-step: personal info → location → security
4. **Dashboard** — Stats grid, escalation warnings, recent complaints
5. **Submit Complaint** — Category picker → details → location
6. **Complaints List** — Tabbed by status, searchable
7. **Complaint Detail** — Full info, escalation timeline, comments
8. **Track** — Search by tracking code (e.g. SR4K9X2M)
9. **Notifications** — Escalations, resolutions, official replies
10. **Profile** — Language toggle, dark mode, logout
11. **Officer Dashboard** — Quick-action cards for government staff

---

*Built for Tanzania 🇹🇿 · Powered by Flutter*
