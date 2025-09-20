# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 奇跡の一枚 (Miracle Shot) - Flutter iOS App

## Overview
A Flutter iOS app that enhances photos using OpenAI's image generation API with adjustable "coolness" levels (1-10). The app prioritizes privacy by removing all EXIF data and not storing any user data.

## OpenAI API Configuration

This app requires an OpenAI API key to function. Set it up by:

1. Create `.env` file from the example:
   ```bash
   cp .env.example .env
   ```
2. Add your OpenAI API key to the `.env` file:
   ```
   OPENAI_API_KEY=your_actual_api_key_here
   ```

Alternatively, run with environment variable:
```bash
flutter run --dart-define=OPENAI_API_KEY=your_api_key_here
```

## Essential Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run

# Run with specific device
flutter run -d [device_id]

# Hot reload (while running)
r

# Hot restart (while running)
R
```

### Build & Release
```bash
# Build for iOS release
flutter build ios --release

# Clean build artifacts
flutter clean

# Update dependencies
flutter pub upgrade
```

### Code Quality
```bash
# Run static analysis
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Architecture Overview

### State Management
- Uses **Provider** pattern with `AppState` class
- Manages strength level (1-10), loading state, and error messages
- Persists user preferences with SharedPreferences

### Screen Flow
1. **HomeScreen** (`home_screen.dart`) - Entry point with image selection
2. **ImageEditorScreen** (`image_editor_screen.dart`) - Preview and strength adjustment
3. **PrivacyExplanationScreen** - Privacy policy display

### Service Layer
Key services in `lib/services/`:
- `ai_enhancement_service.dart` - OpenAI API integration, handles image enhancement with strength levels
- `photo_picker_service.dart` - Gallery image selection using photo_manager
- `photo_save_service.dart` - Saves enhanced images to "奇跡の一枚" album
- `exif_service.dart` - Removes all EXIF metadata from images
- `permission_service.dart` - iOS photo library permission handling
- `error_handler.dart` - Centralized error handling with user-friendly messages

### AI Enhancement Logic
The strength parameter (1-10) maps to different enhancement levels:
- **1**: No enhancement (original image, EXIF removed)
- **2-4**: Light enhancement (subtle improvements)
- **5-7**: Standard enhancement (balanced improvements)
- **8-10**: Maximum enhancement (dramatic improvements)

Implementation details in `ai_enhancement_service.dart`:
- Uses OpenAI's Image Edit API
- Compresses images to stay under 4MB limit
- 30-second timeout for API calls
- Different prompts for each strength level

## iOS Configuration

### Requirements
- iOS 16.0+ (configured in `ios/Podfile`)
- Xcode 14.0+
- CocoaPods for dependency management

### Permissions
Set in `ios/Runner/Info.plist`:
- `NSPhotoLibraryUsageDescription`: Photo library access
- `NSPhotoLibraryAddUsageDescription`: Save enhanced photos

### Running on iOS
```bash
# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Run on simulator
flutter run

# Run on physical device (requires provisioning profile)
flutter run -d [device_id]
```

## Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run in watch mode
flutter test --watch
```

### Test Files
- `test/widget_test.dart` - UI component tests
- `test/providers/app_state_test.dart` - State management tests
- `test/services/exif_service_test.dart` - EXIF removal tests

## Privacy & App Store Compliance

### Privacy Features
- **No data collection**: No analytics, crash reporting, or user tracking
- **No server storage**: Images processed via API are not stored
- **EXIF removal**: All metadata stripped from saved images
- **No ads or IAP**: Completely free app

### App Store Submission
- Submission materials in `app_store/` directory
- Conservative app description to avoid rejection
- Clear privacy policy explaining data handling

## Error Handling

The app uses `ErrorHandler` service for consistent error messages:
- Network errors: Retry option provided
- Large images: Automatic compression
- API failures: User-friendly messages
- Permission denied: Clear instructions

## Development Tips

### Image Processing Flow
1. User selects image from gallery
2. Image loaded and displayed with initial strength (5)
3. User adjusts strength slider
4. On save: compress → enhance via API → remove EXIF → save to library

### API Rate Limits
- OpenAI Image Edit API: $0.020 per image (1024×1024)
- Implement retry logic for transient failures
- Monitor API usage to control costs

### Common Issues
- **Permission errors**: Ensure Info.plist descriptions are set
- **API key not found**: Check .env file and environment variables
- **Build failures**: Run `flutter clean` then `flutter pub get`
- **CocoaPods issues**: Delete `Podfile.lock` and run `pod install`

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.