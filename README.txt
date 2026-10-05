PayBD step 6: QR Pay (My QR + Scan)

1) fvm flutter pub add qr_flutter mobile_scanner
2) Add camera permission (Android + iOS), see chat for the commands
3) Expand-Archive -Path "<ZIP_PATH>" -DestinationPath . -Force
4) fvm flutter analyze
5) fvm flutter run

QR format: paybd://pay?phone=01712345678&amount=500.00 (amount optional)
