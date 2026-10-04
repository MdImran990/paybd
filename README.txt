PayBD step 4: Auth guard + Profile + Change PIN + Settings + Logout

  Expand-Archive -Path "<ZIP_PATH>" -DestinationPath . -Force
  fvm flutter analyze
  fvm flutter run

Guard: without login, every page except Splash/Onboarding/Login/OTP redirects to /login.
Logout clears the session + PIN and resets the demo wallet (all data is in memory).
