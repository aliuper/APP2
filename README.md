# IPTV Editor - High-Performance Flutter Application

Modern, high-performance IPTV playlist editor with background processing and smart filtering capabilities.

## Features

### Core Features
- **High-Performance Processing**: Uses Isolates for background M3U parsing and link testing
- **Smart Country Detection**: Automatically detects and filters channels by country
- **Batch Processing**: Test and process multiple playlists simultaneously
- **Modern UI**: Clean, animated interface with smooth transitions
- **Memory Efficient**: No UI freezing or RAM issues

### Editing Modes

#### Manual Editing
- Load single M3U playlist from URL or file
- Select specific channel groups
- Choose output format (M3U8, M3U, M3U Plus)
- Save filtered playlist to device

#### Automatic Editing
- Upload multiple playlist URLs (max 10)
- Live stream testing with timeout protection
- Smart country-based filtering
- Separate output files for each playlist
- Automatic expiry date extraction

## Technical Specifications

### Architecture
- **Framework**: Flutter 3.19.0+ with Dart
- **State Management**: Riverpod
- **Background Processing**: Isolates for CPU-intensive tasks
- **Performance**: Non-blocking UI with async operations

### Key Components
- `M3UParserService`: Parse M3U files in Isolate
- `LinkTesterService`: Test playlist URLs with concurrent processing
- `CountryDetectorService`: Smart country detection with regex patterns
- `PlaylistModel`: Data model for playlists
- `ChannelModel`: Data model for channels

## Installation & Setup

### Prerequisites
- Flutter SDK 3.19.0 or higher
- Dart SDK compatible with Flutter version
- Android Studio or VS Code with Flutter extensions
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/iptv_flutter.git
   cd iptv_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **App Icons Setup**

   Create or download app icons and place them in the following locations:

   - `assets/icons/icon.png` (1024x1024 pixels)
   - `assets/icons/icon_adaptive.png` (1024x1024 pixels, transparent background)

   The icon should:
   - Be 1024x1024 pixels
   - Use a TV/playlist related design
   - Have good contrast and be easily recognizable
   - Work well at small sizes

4. **Generate app icons**
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## APK Build

### Local Build
```bash
# Release APK
flutter build apk --release --split-per-abi

# App Bundle (for Play Store)
flutter build appbundle --release
```

### GitHub Actions
The project includes automatic APK building through GitHub Actions:

1. Push code to the `main` or `master` branch
2. GitHub Actions will automatically:
   - Build release APKs for different architectures
   - Build app bundle for Play Store
   - Create a new release with downloadable APKs
   - Upload build artifacts

### Required Permissions
The app requires the following permissions:
- **Internet Access**: Download and test M3U playlists
- **Storage Access**: Save filtered playlists to device storage
- **External Storage Management** (Android 11+): Write to Downloads folder

## File Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── channel_model.dart
│   └── playlist_model.dart
├── services/                 # Business logic
│   ├── m3u_parser_service.dart    # M3U parsing (Isolate)
│   ├── link_tester_service.dart    # URL testing (Isolate)
│   └── country_detector_service.dart # Country detection
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── manual_edit_screen.dart
│   └── automatic_edit_screen.dart
└── widgets/                  # Reusable UI components
    ├── app_button.dart
    ├── app_background.dart
    └── channel_group_selector.dart
```

## Performance Optimizations

### Background Processing
- All M3U parsing operations run in separate Isolates
- Link testing uses concurrent processing with configurable limits
- UI thread never blocked by heavy operations

### Memory Management
- Efficient data structures for large channel lists
- Proper disposal of controllers and listeners
- Stream-based operations where possible

### Smart Filtering
- Regex-based country detection optimized for performance
- Lazy loading of channel groups
- Efficient search implementation

## Output Files

### Manual Mode
- Single filtered M3U file saved to Downloads/IPTV_Editor_Outputs/

### Automatic Mode
- Separate M3U file for each working playlist
- Naming format: `Bitis_{DD.MM.YYYY}_{PlaylistName}.m3u`
- All files saved to Downloads/IPTV_Editor_Outputs/

## Country Detection

The app supports automatic detection of 20+ countries including:
- Türkiye (TR, TUR, TURKEY)
- Germany (DE, GER, GERMANY)
- Romania (RO, ROU, ROMANIA)
- Austria (AT, AUT, AUSTRIA)
- And many more...

## Troubleshooting

### Common Issues

1. **Permission Denied on Android 11+**
   - Go to Settings → Apps → IPTV Editor → Permissions
   - Enable "All files access" or "Manage external storage"

2. **Parsing Errors**
   - Ensure M3U files start with `#EXTM3U`
   - Check if URL is accessible
   - Verify internet connection

3. **Slow Performance**
   - Limit concurrent link testing (max 5 by default)
   - Use WiFi for faster downloads
   - Close other apps if device is low on memory

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please create an issue on GitHub.

---

**Note**: This application is designed for educational and personal use only. Users must ensure they have proper rights to modify and redistribute IPTV playlists.