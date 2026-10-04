PayBD step 5: Cash Out + Add Money + Mobile Recharge (one shared payment flow)

1) Delete the old send_money folder (replaced by modules/payment):
   Remove-Item -Recurse -Force lib\modules\send_money
2) Extract this zip into the project root:
   Expand-Archive -Path "<ZIP_PATH>" -DestinationPath . -Force
3) fvm flutter analyze
4) fvm flutter run
