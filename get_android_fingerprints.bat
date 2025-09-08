@echo off
echo ========================================
echo Android SHA-1 and SHA-256 Fingerprints
echo ========================================
echo.

echo Getting SHA-1 and SHA-256 fingerprints for Firebase Console...
echo.

echo SHA-1 Fingerprint:
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr "SHA1"

echo.
echo SHA-256 Fingerprint:
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr "SHA256"

echo.
echo ========================================
echo Instructions:
echo ========================================
echo 1. Copy the SHA-1 fingerprint above
echo 2. Go to Firebase Console ^> Project Settings
echo 3. Scroll to "Your apps" section
echo 4. Find your Android app and click "Add fingerprint"
echo 5. Paste the SHA-1 fingerprint
echo 6. Repeat for SHA-256 fingerprint
echo 7. Click Save
echo.
echo ========================================
echo Test Phone Numbers for Development:
echo ========================================
echo Phone: +1 650-555-3434
echo Code: 123456
echo.
echo Phone: +1 650-555-1234
echo Code: 654321
echo.
echo Add these in Firebase Console ^> Authentication ^> Sign-in method ^> Phone ^> Phone numbers for testing
echo.
pause
