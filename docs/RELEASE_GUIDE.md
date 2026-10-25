# PayBD release guide (Android)

Read the "Before you publish" part first. It matters more than the build commands.

## 0. Before you publish

PayBD is a **demo**: balances, transactions, OTP and fees are fake. Real money in
Bangladesh needs a **Bangladesh Bank licence** (or a licensed partner such as a bank or
an existing MFS) and a real backend.

- Google Play has a **Financial services policy** and asks you to declare what the app does.
  A demo that *looks* like a wallet should say clearly, in the title or description, that it is a
  demo / prototype and does not move real money (the app already says this on its screens).
- Do not use another company's name, logo or colours as your own brand.
- Start with an **Internal testing** track (only people you invite). Do not go public until the
  backend, licence, privacy policy and security review are done.

This guide is not legal advice. Ask a lawyer to review the Terms and the Privacy Policy.

## 1. Fix the app identity (once)

- Package name is `com.paybd.paybd`. After the first upload to Play it can never change.
  If you want another name (for example `com.yourcompany.paybd`), change it NOW.
- App name on the phone: `PayBD` (already set).
- Replace the placeholder icon (`assets/icon/icon.png`, `assets/icon/icon_fg.png`) with your
  real logo, then run: `fvm dart run flutter_launcher_icons`

## 2. Version

In `pubspec.yaml`: `version: 0.3.0+1`
- `0.3.0` is what people see.
- `+1` is the build number. It must go up by 1 for every upload to Play (`+2`, `+3` ...).

## 3. Create the signing key (once, keep it forever)

If you lose this key you can never update the app.

PowerShell (keytool comes with Android Studio):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v `
  -keystore "$env:USERPROFILE\paybd-upload-keystore.jks" `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Choose a strong password and write it in a password manager.
- **Back the .jks file up** (USB, private cloud). Never put it in git.

Create `android\key.properties` (copy `android\key.properties.example`):

```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=C:/Users/YOUR_NAME/paybd-upload-keystore.jks
```

Add these two lines to `.gitignore` if you use git:

```
android/key.properties
*.jks
```

## 4. Tell Gradle to use the key

Open `android/app/build.gradle.kts`.

At the very top add:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Inside `android { ... }` add `signingConfigs` (above `buildTypes`) and change the release build type:

```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
```

(If `buildTypes { release { ... } }` already exists, only replace its `signingConfig` line.)

## 5. Build

Test on a real phone first (a normal APK):

```powershell
fvm flutter build apk --release
```

File: `build\app\outputs\flutter-apk\app-release.apk`

For Google Play (an App Bundle, smaller and required for new apps):

```powershell
fvm flutter build appbundle --release --obfuscate --split-debug-info=build\symbols
```

File: `build\app\outputs\bundle\release\app-release.aab`

Keep the `build\symbols` folder for each version. It lets you read crash stack traces later.

## 6. Check the release build

- Install the release APK and go through: register, PIN, send money, receipt, Statement PDF,
  fingerprint, QR scan, Bangla mode, log out and log in again.
- Turn off "Block screenshots" only for your own screenshots, then turn it on again.
- Test on a low-end phone and on Android 8 or older if you can (fingerprint prompt needs an
  AppCompat theme on Android 8 and below).

## 7. Google Play Console

1. Create a developer account (one-time fee; check the current fee and identity checks).
2. Create the app: name, default language, "App", "Free".
3. Main store listing: see `STORE_LISTING.md` (short description, full description, screenshots,
   feature graphic 1024x500, icon 512x512).
4. App content: privacy policy URL (see `PRIVACY_POLICY_TEMPLATE.md`, publish it on a web page),
   Data safety form, content rating, target audience, financial features declaration.
5. Testing: upload the `.aab` to **Internal testing**, add tester emails, share the link.
   New personal developer accounts may have to run a **closed test** with a minimum number of
   testers for some days before production. Check the current rule in Play Console.
6. Only after the backend and licence are ready: production release.

### Data safety answers for the demo build (check them against your final app)

- Data collected: phone number, name (optional), profile photo (optional), transaction records (demo).
- Where it is stored: on the device only. Nothing is sent to a server.
- Encryption: the PIN is stored as a salted hash in the Android Keystore-backed secure storage.
- Users can delete their data: yes (Settings > Delete this account).

When the real backend arrives these answers change (data is sent to your server). Update them.

## 8. Checklist

- [ ] Real logo in place
- [ ] Package name final
- [ ] Signing key created and backed up
- [ ] `version` raised
- [ ] Release APK tested on a real phone
- [ ] Privacy policy and Terms reviewed by a lawyer and published
- [ ] Store listing text and screenshots ready
- [ ] Demo wording kept in the listing
- [ ] Licence and backend ready before any real-money release
