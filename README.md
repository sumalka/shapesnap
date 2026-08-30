ShapeSnap - Setup Guide


1. Clone Repository

   git clone https://github.com/sumalka/shapesnap.git
   cd shapesnap



2. Install Dependencies

   flutter pub get



3. Generate Hive Adapters

   flutter pub run build_runner build --delete-conflicting-outputs



4. Firebase Setup

4.1 Create Firebase Project
- Go to https://console.firebase.google.com/
- Click "Add project" → Name: shapesnap


4.2 Enable Email Authentication
- Firebase Console → Authentication → Sign-in methods
- Enable Email/Password → Save


4.3 Android Setup
- Firebase Console → Add app → Android
- Package name: `com.shapesnap.app`
- Download `google-services.json`
- Place in: `shapesnap/android/app/google-services.json`


4.4 iOS Setup (Mac only)
- Firebase Console → Add app → iOS
- Bundle ID: `com.shapesnap.app`
- Download `GoogleService-Info.plist`
- Place in: `shapesnap/ios/Runner/GoogleService-Info.plist`


4.5 Install iOS Pods (Mac only)

   cd shapesnap/ios
   pod install
   cd ..


5. Check Model Files

   ls -la shapesnap/assets/model/
   Should show: shapesnap_model.tflite and labels.txt



6. Run the App

   flutter run



7. Build APK

   **Release APK**

   flutter build apk --release

   Output: `shapesnap/build/app/outputs/flutter-apk/app-release.apk`



   **Split APKs (smaller)**

   flutter build apk --split-per-abi --release
   Output: `shapesnap/build/app/outputs/flutter-apk/`



   **App Bundle (Google Play)**

   flutter build appbundle --release
   Output: `shapesnap/build/app/outputs/bundle/release/app-release.aab`



8. Troubleshooting

   **Build Errors**

   flutter clean
   flutter pub get



   **Hive Errors**

   flutter pub run build_runner build --delete-conflicting-outputs



   **iOS Issues (Mac)**

   cd shapesnap/ios
   pod deintegrate
   pod install
   cd ..



   **Check Connected Devices**

   flutter devices



Firebase Not Working
- Verify `shapesnap/android/app/google-services.json` exists
- Check package name matches Firebase project



**Packages Used**


dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.9
  provider: ^6.1.5+1
  camera: ^0.12.0+1
  image_picker: ^1.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5
  shared_preferences: ^2.5.5
  path: ^1.9.1
  image: ^4.9.1
  firebase_core: ^4.9.0
  firebase_auth: ^6.5.1
  firebase_analytics: ^12.4.1
  firebase_database: ^12.4.1
  cloud_firestore: ^6.7.1
  go_router: ^17.2.3
  intl: ^0.20.2
  permission_handler: ^12.0.2
  audioplayers: ^6.7.0
  lottie: ^3.3.3
  just_audio: ^0.10.5
  google_fonts: ^8.1.0
  flutter_native_splash: ^2.4.8
  flutter_launcher_icons: ^0.14.4
  rive: ^0.14.7
  tflite_flutter: ^0.12.1
  http: ^1.6.0
  connectivity_plus: ^7.3.0
  url_launcher: ^6.3.2

dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.15.0




