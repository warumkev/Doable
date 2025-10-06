<img width="20%" height="20%" alt="DobaleAppIcon-iOS-Default-1024x1024@1x" src="https://github.com/user-attachments/assets/52fda66d-0ece-48bc-a9d4-ce47c24a6ae7" />

# Doable - The To-do App with the Focus Twist
Doable is a minimalist to-do app for iOS designed to combat procrastination and sharpen focus. The key feature is a unique timer that only runs when the device is held in landscape mode—a simple but effective method to minimize digital distractions.

<table border="0" cellpadding="4" cellspacing="0">
  <tbody>
    <tr>
      <td width="33.33%"><img src="https://github.com/user-attachments/assets/9d3425bb-555d-461c-83c2-16c6704f58a3" alt="Abstract colorful pattern" width="100%"></td>
      <td width="33.33%"><img src="https://github.com/user-attachments/assets/6c2625b4-c52a-4bc3-85d6-6d16aa12fe0c" alt="Close-up of colorful swirls" width="100%"></td>
      <td width="33.33%"><img src="https://github.com/user-attachments/assets/152c2bff-1cee-4137-8256-aec71a728f43" alt="Vibrant abstract design" width="100%"></td>
    </tr>
    <tr>
      <td colspan="3"><img src="https://github.com/user-attachments/assets/f105e679-8391-432c-b509-9626ce495eac" alt="Wide panoramic abstract art" width="100%"></td>
    </tr>
  </tbody>
</table>

## About the Project
We live in a world full of distractions. A simple to-do list is often not enough to be truly productive. Doable solves this problem by forcing a conscious decision to focus. By turning the device into landscape mode, the user signals: "Now, I am concentrating on this one task."

The project is written entirely in SwiftUI and uses modern Apple technologies like SwiftData for purely local and private data storage.

## Key Features

- ✅ Minimalist To-do Management: Create, complete, and manage your tasks in a clean and intuitive interface.
- ⏱️ Orientation-Based Focus Timer: Start a timer for a task that only runs in landscape mode. If you turn your phone back, it pauses – guaranteeing you stay on track.
- 📊 Statistics & Streaks: Track your completed tasks, recognize patterns, and stay motivated by collecting "streaks."
- 🔒 100% Private: No accounts, no tracking, no cloud. All your data is stored exclusively locally on your device.
- 😄 Playful Approach: Humorous texts and a motivating design make productivity an entertaining experience.
- 🌐 Multilingual: Supports multiple languages, including English, German, Spanish, and Japanese.

## Tech Stack
- Framework: SwiftUI
- Language: Swift
- Database: SwiftData
- Target Platform: iOS

The project is "local-first," meaning all core functions work without a network connection.

## Getting Started
To run and develop the project locally, follow these steps.

## Prerequisites

- macOS with the latest version of Xcode
- Basic knowledge of Swift and SwiftUI

## Installation

Clone the repository:

```bash 
git clone [https://github.com/your-username/Doable.git](https://github.com/your-username/Doable.git)
```

Open the project: Navigate to the project folder and open the Doable.xcodeproj file with Xcode.

```bash
cd Doable
xed .
```

Run the app: Select a simulator or a connected iOS device and click "Run" (▶). The app will compile and start.

## Project Structure
The code is logically structured to ensure a clear separation of concerns.

```
Doable/
├── Models/
│   └── Todo.swift          # The SwiftData @Model for a task.
├── Views/
│   ├── ContentView.swift   # The main view with the to-do list.
│   ├── FullscreenTimerView.swift # The logic for the focus timer.
│   ├── StatisticsView.swift  # The view for user statistics.
│   └── SettingsView.swift    # The settings page.
│   └── ...                 # Other UI components.
├── Utilities/
│   ├── DisappointmentStrings.swift # Collection of "disappointed" timer messages.
│   └── NewTodoNames.swift  # Suggestions for new tasks.
├── Ressources/
│   └── Assets.xcassets     # All app icons, colors, and images.
├── *language*.lproj/
│   └── Localizable.strings # All localized texts of the app.
└── DoableApp.swift         # The main entry point of the app.
```

## Privacy
Privacy is a core feature of Doable.

- No Data Collection: The app does not use any third-party analytics tools or trackers.
- No User Accounts: Registration is not required.
- Local Storage: All data (tasks, completion times, etc.) is stored exclusively on the user's device using SwiftData. Data only leaves the device if the user actively uses the export function.

## Contributing
Contributions are welcome! If you have ideas for new features or find a bug, please create an "Issue" to discuss it. Pull requests are also very welcome.

## License
This project is licensed under the MIT License. For more information, see the LICENSE file.

