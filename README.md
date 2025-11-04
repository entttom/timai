# Timai - The modern Kimai client for iOS

A native iOS time tracking app for [Kimai v2](https://www.kimai.org/), built with SwiftUI and following modern iOS development best practices.

<p align="center">
  <img src="screenshots/Simulator Screenshot - iPhone 17 Pro - 2025-11-04 at 20.56.21.png" width="250" />
  <img src="screenshots/Simulator Screenshot - iPhone 17 Pro - 2025-11-04 at 20.56.26.png" width="250" />
  <img src="screenshots/Simulator Screenshot - iPhone 17 Pro - 2025-11-04 at 20.56.33.png" width="250" />
</p>

## Features

- ✅ **Secure Authentication**: Login with your Kimai v2 API token, securely stored in the iOS Keychain
- ⏱️ **Timesheet Management**: View, create, edit, and delete time entries
- 📊 **Comprehensive Reports**: 
  - Personal weekly, monthly, and yearly views
  - Team-wide reports for all users
  - Project details with budget tracking
  - Project overview and evaluation
  - Monthly evaluations and inactive projects tracking
- 💰 **Budget Tracking**: Visual representation of project time budgets and progress
- 🌍 **Multi-language Support**: Full German and English localization
- 🎨 **Modern UI**: Clean, native iOS interface built with SwiftUI
- 📱 **iOS Native**: Optimized for iPhone and iPad

## Technology Stack

- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **API**: Kimai v2 REST API
- **Dependencies**: 
  - [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) - Secure credential storage
- **Dependency Manager**: Carthage
- **Language**: Swift 5+

## Requirements

- iOS 15.0 or later
- Xcode 14.0 or later
- Kimai v2 server with API access
- Valid Kimai API token

## Build from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/entttom/timai.git
   cd timai
   ```

2. **Install Carthage** (if not already installed):
   ```bash
   brew install carthage
   ```

3. **Install dependencies**:
   ```bash
   carthage update --platform iOS --use-xcframeworks
   ```

4. **Open the project**:
   ```bash
   open Timai.xcodeproj
   ```

5. **Build and run**:
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

> **Note**: You may need to update the team and bundle identifier in the project settings to run on your device.

## Usage

1. Launch the app
2. Enter your Kimai server URL (e.g., `https://demo.kimai.org/api/`)
3. Enter your API token (generate one in your Kimai profile settings)
4. Start tracking your time!

## Project Structure

```
Timai/
├── Model/              # Data models (Timesheet, Project, Customer, etc.)
├── Views/              # SwiftUI views
│   ├── Timesheet/      # Time tracking views
│   ├── Reports/        # Report views
│   └── Settings/       # Settings views
├── ViewModels/         # View models for business logic
├── Services/           # Network and API services
├── Components/         # Reusable UI components
└── Helper/             # Utility files and extensions
```

## License

This project is licensed under the **Business Source License 1.1** (BSL).

- **Non-commercial and personal use**: Free
- **Commercial use**: Requires a commercial license

The license will automatically convert to the Mozilla Public License Version 2.0 on January 1, 2029.

See [LICENSE](LICENSE) for full details.

## Credits

This project was inspired by [Timeu](https://github.com/bastilimbach/timeu) by [Sebastian Limbach](https://github.com/bastilimbach). Timai represents a complete rewrite in SwiftUI with support for the Kimai v2 API.

Special thanks to:
- Sebastian Limbach for the original Timeu project and inspiration
- The Kimai team for developing an excellent open-source time tracking solution
- All contributors and open-source maintainers whose libraries made this project possible

## Contributing

Contributions are welcome! If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows Swift best practices and includes appropriate comments.

## Roadmap

- [ ] App Store submission
- [ ] Offline mode with local caching
- [ ] Dark mode optimization
- [ ] Widget support for quick time tracking
- [ ] Apple Watch companion app
- [ ] Siri shortcuts integration
- [ ] Automated testing and CI/CD

## Support

If you encounter any issues or have questions:

- Open an [issue](https://github.com/entttom/timai/issues) on GitHub
- Check the [Kimai documentation](https://www.kimai.org/documentation/) for API-related questions

## Author

**Dr. Thomas Entner**

- GitHub: [@entttom](https://github.com/entttom)

---

Made with ❤️ for the Kimai community
