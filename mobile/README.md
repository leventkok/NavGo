# NavGo Mobile

Flutter client — product hierarchy inspired by [AURA](https://github.com/masterfabric-mobile/masterfabric_core/tree/feature/aura-example-v2/example_v2), feature architecture like [Gastromic/mobile](https://github.com/leventkok/Gastromic/tree/main/mobile).

## Product flow

```text
Splash → Onboarding (welcome / name / tempo / interests / group / transport)
      → Shell tabs
          Plan  | Trips | Explore | Profile
```

City/district comes from GPS (or manual fallback). Preferences bias Places queries and route `travel_mode`.

| Tab | Role |
|-----|------|
| **Plan** | Prompt → grounded Places → route (BLoC) |
| **Trips** | Saved itineraries (empty state for now) |
| **Explore** | Area ideas |
| **Profile** | Name, location, prefs, API base, reset onboarding |

## Packages

Uses [`masterfabric_core`](https://pub.dev/packages/masterfabric_core) `^1.0.0` for bootstrap (`MasterApp.runBefore`, config, storage helpers).

```yaml
dependencies:
  masterfabric_core: ^1.0.0
```

Note: Core **2.x** (AURA / `masterfabric-mobile`) needs Flutter ≥ 3.44. This app stays on **1.0.0** while the local Flutter SDK is 3.41. After upgrading Flutter, you can switch to:

```yaml
masterfabric_core:
  git:
    url: https://github.com/masterfabric-mobile/masterfabric_core.git
```

## Structure

```text
lib/
  flavors/                            # main_dev / main_prod + app_flavor
  app/app.dart + routes.dart          # GoRouter + shell (NavGoRoutes)
  data/session_repository.dart        # onboarding prefs
  views/
    splash/ onboarding/
    plan/          # View + ViewModel(Bloc) + service + widgets
    trips/ explore/ profile/
  widgets/navgo_shell.dart            # bottom tab bar
  core/                               # theme, models, extensions
assets/config/
  app_config_dev.json
  app_config_prod.json
```

## Flavors

| Flavor | Entry | App id (Android / iOS) | Config |
|--------|-------|------------------------|--------|
| **dev** | `lib/flavors/main_dev.dart` | `…navgo_mobile` / `…navgoMobile` | `app_config_dev.json` |
| **prod** | `lib/flavors/main_prod.dart` | `…navgo_mobile` / `…navgoMobile` | `app_config_prod.json` |

Both flavors share the same app name and bundle id (**NavGo**). Which flavor is running is chosen by `--flavor` / `-t`.

Prod API URL is still local for now; update `assets/config/app_config_prod.json` when ready.

## Design

Modern Navigation palette: Primary `#2D9CDB`, Secondary `#333333`, Tertiary `#CA850C`, Neutral `#73777C`, Inter, 16–24 radius.

## Run

```bash
cd ../masterfabric-go && make run

cd ../mobile
# Dev (default day-to-day)
flutter run --flavor dev -t lib/flavors/main_dev.dart

# Prod
flutter run --flavor prod -t lib/flavors/main_prod.dart
```
