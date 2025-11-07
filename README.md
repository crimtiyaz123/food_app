# Food Delivery App

A complete Flutter food delivery application with Firebase authentication.

## Features

- **Email/Password Authentication**: Register and login with email
- **Phone Number Authentication**: OTP verification for phone numbers
- **Google Sign-in**: Social authentication (currently disabled due to package issues)
- **Forgot Password**: Email-based password reset
- **Modern UI**: Italian-themed design with gradients and cards

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable Authentication and Firestore Database

### 2. Enable Phone Authentication
1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Enable **Phone** authentication
3. Add your phone number for testing (optional)
4. For production, you'll need to verify your domain

### 3. Configure Firebase in Flutter
1. Install FlutterFire CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Configure project: `flutterfire configure`
4. This generates `firebase_options.dart`

### 4. Phone Authentication Testing
- Use test phone numbers from Firebase Console
- For real numbers, ensure proper domain verification
- Check Firebase billing/quota for SMS costs

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on web (recommended)
flutter run -d chrome

# Run on Android
flutter run -d android
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart       # Firebase config
├── services/
│   └── auth_service.dart       # Authentication logic
├── widgets/
│   └── custom_field.dart       # Reusable input field
└── screens/
    ├── customer/
    │   ├── home_screen.dart    # Welcome screen
    │   ├── login_screen.dart  # Login page
    │   └── auth/
    │       ├── signup_screen.dart      # Registration
    │       ├── otp_verification_screen.dart  # Phone verification
    │       └── forgot_password_screen.dart   # Password reset
```

## Troubleshooting

### OTP Not Sending
1. Check Firebase Console > Authentication > Phone numbers
2. Verify phone number format: `+91XXXXXXXXXX`
3. Check browser console for errors
4. Ensure Firebase project has billing enabled for SMS

### Common Issues
- **Phone Auth**: Enable in Firebase Console
- **Web Setup**: Configure authorized domains
- **Package Updates**: Some packages may need updates

## Future Enhancements

- Menu management with Firestore
- Cart functionality
- Order tracking with Google Maps
- Payment integration
- Push notifications
- Admin dashboard

## License

This project is for educational purposes.
