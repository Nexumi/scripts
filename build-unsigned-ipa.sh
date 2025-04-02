PROJECT=$(find . -type d -name "*.xcodeproj" -print -quit | xargs -I {} basename {} .xcodeproj)

if xcodebuild archive -project "${PROJECT}.xcodeproj" -scheme "${PROJECT}" -archivePath unsigned.xcarchive -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO; then
    echo "xcodebuild succeeded. Proceeding with packaging."

    mv unsigned.xcarchive/Products/Applications .
    rm -rf unsigned.xcarchive
    mv Applications Payload
    zip -r App.ipa Payload
    rm -rf Payload

    echo "App.ipa successfully created."
else
    echo "xcodebuild failed. Exiting."
    exit 1
fi
