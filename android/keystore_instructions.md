# Creating a Signed APK in Android Studio

## Opening the Project in Android Studio
1. Open Android Studio
2. Select "Open an existing Android Studio project"
3. Navigate to `/Users/ranjith/trackmywork/android` and click "Open"

## Creating a Keystore
1. In Android Studio, go to **Build** > **Generate Signed Bundle / APK**
2. Select "APK" and click "Next"
3. In the Key store path section, click "Create new..."
4. Fill in the following information:
   - **Key store path**: Choose a location to save your keystore (e.g., `/Users/ranjith/trackmywork/android/app/keystore/trackmywork.keystore`)
   - **Password**: Create a strong password (remember this password!)
   - **Confirm**: Re-enter the same password
   - **Key alias**: `trackmywork`
   - **Password**: Same as the keystore password (or create a different one if you prefer)
   - **Confirm**: Re-enter the key password
   - **Validity (years)**: 25 (or any number of years you prefer)
   - **Certificate information**: Fill in your details (name, organization, etc.)
5. Click "OK" to create the keystore

## Creating a Signed APK
1. After creating the keystore (or if you already have one), select it in the "Key store path" field
2. Enter the keystore password and key alias/password you created
3. Click "Next"
4. Select "release" build variant
5. Check both "V1 (Jar Signature)" and "V2 (Full APK Signature)"
6. Click "Finish"

## Alternative: Using Gradle Command Line
If you prefer using the command line, you can create a `key.properties` file in the `android` directory with the following content:

```
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=trackmywork
storeFile=../app/keystore/trackmywork.keystore
```

Then run:
```
flutter build apk --release
```

## Important Notes
1. **KEEP YOUR KEYSTORE SECURE!** If you lose it, you won't be able to update your app on the Play Store.
2. **REMEMBER YOUR PASSWORDS!** Store them securely.
3. The keystore file and key.properties should NOT be committed to version control.
