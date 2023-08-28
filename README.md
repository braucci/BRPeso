## App Functionality and Technical Choices

### Functionality
The application serves as a weight monitoring tool for users over time. Users can record new weight entries, edit them, or delete them. Additionally, these entries are displayed in chronological order, and the weight difference between the first and last entry is also shown to the user.

### Technical Choices
- **Development Framework**: The app is developed in SwiftUI.
- **Data Persistence**: Uses `UserDefaults` for storing data.
- **Data Structure**: Utilizes a `WeightEntry` object, which is a struct conforming to both `Identifiable` and `Codable` protocols, for each weight entry. This design choice allows for easy data management and encoding/decoding.
- **Security**: Implements a biometric authentication mechanism using `LocalAuthentication` to secure user data.

### Views
- **ContentView**: Manages the main display of entries and user interaction.
- **EditView**: Used for modifying individual weight entries.
