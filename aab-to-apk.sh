#!/bin/bash

# https://stackoverflow.com/questions/53040047/generate-an-apk-file-from-an-aab-file-android-app-bundle
# http://www.androiddevelopment.org/2009/01/19/signing-an-android-application-for-real-life-mobile-device-usage-installation

if ! command -v java &>/dev/null; then
	echo "Please install Java 11 or higher to use this script"
	exit 1
fi

AAB_FILE=$(find . -type f -name "*.aab" -print -quit)

if [ -n $AAB_FILE ]; then
	echo "Found $AAB_FILE"
else
	echo "No Android App Bundle (.aab) file found"
	exit 1
fi

BUNDLETOOL_FILE=$(find . -type f -name "bundletool-all-*.jar" -print -quit)
if [ -z $BUNDLETOOL_FILE ]; then
	echo "Bundletool not found"
	BUNDLETOOL_URL="https://github.com/google/bundletool/releases/latest"
	BUNDLETOOL_VERSION=$(curl -Ls -w "%{url_effective}\n" -o /dev/null $BUNDLETOOL_URL | sed -E 's/.*tag\/([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
	if [ -z $BUNDLETOOL_VERSION ]; then
		echo "Could not automatically download bundletool"
		echo "Please download the latest bundletool from $BUNDLETOOL_URL"
		exit 1
	else
	  echo "Downloading bundletool v$BUNDLETOOL_VERSION"
		BUNDLETOOL_DOWNLOAD_URL="https://github.com/google/bundletool/releases/latest/download/bundletool-all-$BUNDLETOOL_VERSION.jar"
		curl -OL $BUNDLETOOL_DOWNLOAD_URL
		BUNDLETOOL_FILE="./bundletool-all-$BUNDLETOOL_VERSION.jar"
	fi
fi

KEY_PASS="jpkit"
if [ ! -f "my-release-key.keystore" ]; then
	echo "Signing key not found"
	keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -validity 10000 -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown" -storepass $KEY_PASS
fi

echo "Building apk..."
java -jar $BUNDLETOOL_FILE build-apks --bundle=$AAB_FILE --output=app.apks --mode=universal --ks=my-release-key.keystore --ks-pass=pass:$KEY_PASS --ks-key-alias=alias_name
if ! unzip -p app.apks universal.apk > app.apk; then
	echo "Failed to generate apk file"
	rm app.apk
	exit 1
fi
rm app.apks
echo "Done"
