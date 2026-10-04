PayBD step 2: Onboarding + Login + OTP

Extract into the project root (overwrites app_router.dart and splash_screen.dart):
  Expand-Archive -Path "<ZIP_PATH>" -DestinationPath . -Force
  fvm flutter analyze
  fvm flutter run

Flow: Splash -> Onboarding -> Login (phone) -> OTP -> Home
Demo OTP: 123456 (mock only, no real SMS)
