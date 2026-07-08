# luxo_request_mi — LUXO Place Request Management

A lightweight, cross-platform **Flutter** app for submitting and tracking service requests for **LUXO Place**. It's a smaller, simpler implementation of the Luxo requests workflow: submit a request, keep a local history, and reach the underlying request portal through an embedded web view.

## Features

- **Submit requests** — create a new service request from the request screen.
- **Request history** — review previously submitted requests, with a dedicated detail view for each entry.
- **Embedded web view** — interact with the LUXO request portal in-app via `flutter_inappwebview`.
- **First-run setup** — a setup screen to configure the app on first launch.
- **Settings** — adjust app preferences.
- **Local persistence** — state and history are saved on-device with `shared_preferences`.
- **Cross-platform** — Android, iOS, web, Windows, macOS, and Linux from one codebase.

## Tech Stack

| Area | Technology |
|------|-----------|
| Framework | Flutter (Dart, SDK 3.8+) |
| State management | `provider` |
| Local storage | `shared_preferences` |
| Web view | `flutter_inappwebview` |
| Utilities | `intl`, `file_picker`, `path_provider`, `uuid` |

## Project Structure

```
lib/
├── models/      # Data models
├── providers/   # State management (Provider)
├── screens/     # home, request, history, history_detail, settings, setup, webview
└── main.dart    # App entry point
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.8 or newer
- A target device/emulator or a desktop/web target

### Setup

```bash
git clone https://github.com/AmanyaPhillip/luxo_request_mi.git
cd luxo_request_mi

flutter pub get
flutter run
```

## Related

This is the streamlined counterpart to [`request_app`](https://github.com/AmanyaPhillip/request_app), which automates Luxo Place request submissions.

## License

Licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
