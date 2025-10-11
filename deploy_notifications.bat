@echo off
echo ========================================
echo  CivicLense - Push Notification Setup
echo ========================================
echo.

echo Step 1: Installing Cloud Functions dependencies...
cd firebase_functions
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo.

echo Step 2: Deploying Cloud Functions to Firebase...
call firebase deploy --only functions:sendPushNotification,functions:sendBulkPushNotifications,functions:onConcernStatusChange,functions:onNewConcernComment
if errorlevel 1 (
    echo ERROR: Failed to deploy functions
    pause
    exit /b 1
)
echo.

echo ========================================
echo  Deployment Complete!
echo ========================================
echo.
echo Push notifications are now active!
echo.
echo Next steps:
echo 1. Run the Flutter app
echo 2. Log in as a user
echo 3. Check console for: FCM token saved
echo 4. Test by updating a concern status
echo.
pause

