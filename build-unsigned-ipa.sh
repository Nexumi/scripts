PROJECT=$(find . -type f -name "*.xcodeproj" -print -quit | xargs -I {} basename {} .xcodeproj)

xcodebuild archive -project ${PROJECT}.xcodeproj -scheme ${PROJECT} -archivePath unsigned.xcarchive -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
mv unsigned.xcarchive/Products/Applications .
rm -rf unsigned.xcarchive
mv Applications Payload
zip -r App.ipa Payload
rm -rf Payload
