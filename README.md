# nFitness
An alternative to the official eFitness app, built with Flutter and Dart.

<<<<<<< HEAD
<a href="https://codeberg.org/nxr/nfitness/releases">
    <img alt="Get it on Codeberg" src="https://get-it-on.codeberg.org/get-it-on-white-on-black.png" height="54">
</a>

<a href="https://apps.obtainium.imranr.dev/redirect?r=obtainium://add/https://github.com/nyxiereal/nFitness/">
<img src="https://github.com/ImranR98/Obtainium/raw/main/assets/graphics/badge_obtainium.png"
alt="Get it on Obtainium" height="54" /></a>
=======
<a href="https://github.com/nyxiereal/nFitness/releases">
<img src="https://user-images.githubusercontent.com/69304392/148696068-0cfea65d-b18f-4685-82b5-329a330b1c0d.png"
alt="Download from GitHub releases" align="center" height="80" /></a>

<a href="https://apps.obtainium.imranr.dev/redirect?r=obtainium://add/https://github.com/nyxiereal/nFitness/">
<img src="https://github.com/ImranR98/Obtainium/raw/main/assets/graphics/badge_obtainium.png"
alt="Get it on Obtainium" align="center" height="54" /></a>
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80

## Feature comparison
| Feature                                 | eFitness | nFitness |
| --------------------------------------- | -------- | -------- |
| Logging into your eFitness club account | ✅        | ✅        |
| Viewing your membership details         | ✅        | ✅        |
| Viewing your club's schedule            | ✅        | ✅        |
| Booking classes                         | ✅        | ✅        |
| Viewing workout history                 | ✅        | ✅        |
| Integrating with wearables              | ✅        | ✅        |
| Viewing the opening hours of your club  | ✅        | ✅        |
| Requires logging into a Google account  | ✅        | ❌        |
| Open source                             | ❌        | ✅        |
| Clear and simple Overview page          | ❌        | ✅        |
| Local gender selection                  | ❌        | ✅        |

## Why nFitness?
I built this app after I found the official eFitness app to be too bloated and not user-friendly. I wanted a simple, open-source alternative that adheres to the Material Design guidelines and provides a faster experience. After 3 days of PCAPDroid-ing the official app, recreating requests in Python, and eventually building the entire app in Flutter. The app is **really** fast, practical, and easy to use. It has most of the features that I can test. I plan on updating it once issues arise or new features are requested/implemented into the official app.

## Screenshots
<details>
   <summary>Click to reveal!</summary>
<<<<<<< HEAD
   <img src="https://codeberg.org/nxr/nfitness/raw/branch/main/.codeberg/1.webp" />
   <img src="https://codeberg.org/nxr/nfitness/raw/branch/main/.codeberg/2.webp" />
   <img src="https://codeberg.org/nxr/nfitness/raw/branch/main/.codeberg/3.webp" />
   <img src="https://codeberg.org/nxr/nfitness/raw/branch/main/.codeberg/4.webp" />
=======
    <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/6612674a-d5da-4698-9614-6da0f42d0cd7" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/10a439e5-17e1-403c-958c-ba90e28cf359" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/8affa1a4-59f8-4447-886f-f6bd6f8bba2b" />
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/80814d6b-0e4f-455c-b527-a8b32a993b60" />
>>>>>>> 7b2c520f4fcf6ed22aee5ebbc62b1dbe212acb80
</details>

## Installation & usage
> [!NOTE]
> This app is officially only compiled for ARM and ARM64 Android devices, if you want to compile it for x86 Android follow the dev guide
1. Go to the releases tab
2. Download the latest APK file
3. Install the APK on your Android device
4. Open the app, select your club, and log in with your designated credentials
5. Enjoy!
6. Found an issue? Open an issue on GitHub!

## Development
1. Install the full Flutter SDK from [flutter.dev](https://docs.flutter.dev/get-started/install)
2. Clone the repository
   ```bash
   git clone https://github.com/nyxiereal/nfitness
   ```
3. In the repository root, install the dependencies
   ```bash
   flutter pub get
   ```
4. Run the app
   ```bash
   flutter run
   ```
5. Compile and test the app
    > [!NOTE]
    > If you want to build for x86 Android, change the target platform to `android-x64` in the build command
    > You can read more about this here, https://developer.android.com/ndk/guides/abis
    ```bash
    flutter build apk --target-platform android-arm,android-arm64
    ```

## TODO
- [ ] Email changing
- [ ] Password changing
- [ ] Multi-club support
- [ ] Club capacity estimation based on the Classes page
- [ ] Release on F-Droid