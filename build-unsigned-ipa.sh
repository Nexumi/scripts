xcodebuild archive -project tpcard.xcodeproj -scheme tpcard -archivePath unsigned.xcarchive -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
mv unsigned.xcarchive/Products/Applications .
rm -rf unsigned.xcarchive
mv Applications Payload
zip -r App.ipa Payload
rm -rf Payload
