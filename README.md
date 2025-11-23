# 🔐 Google Auth Template - Flutter + Firebase

এই template টি যেকোনো Flutter project এ copy-paste করে সহজেই Google Authentication implement করতে পারবেন।

---

## 📦 Part 1: Initial Setup (একবার করলেই হবে)

### Step 1: Firebase CLI & FlutterFire CLI Install

```bash
# Firebase CLI install
npm install -g firebase-tools

# অথবা macOS এ
curl -sL https://firebase.tools | bash

# Firebase login
firebase login

# FlutterFire CLI install
dart pub global activate flutterfire_cli

# Path add করুন (যদি না থাকে)
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Step 2: Firebase Project তৈরি করুন

1. যান: https://console.firebase.google.com/
2. **Add project** → Project name দিন (e.g., "MyApp Dev")
3. Google Analytics enable করুন (optional)
4. **Create project**

### Step 3: Google Sign-In Enable করুন

1. Firebase Console → **Authentication**
2. **Get Started** → **Sign-in method**
3. **Google** select → **Enable** → Support email দিন → **Save**

---

## 🚀 Part 2: নতুন Project এ Setup (প্রতিবার)

### Step 1: Flutter Project তৈরি করুন

```bash
flutter create my_new_app
cd my_new_app
```

### Step 2: Dependencies Add করুন

**pubspec.yaml** এ add করুন:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  google_sign_in: ^6.2.1
  
  # Optional (recommended)
  provider: ^6.1.1  # State management
```

```bash
flutter pub get
```

### Step 3: Firebase Configure করুন

```bash
flutterfire configure
```

**Select করুন:**
- Firebase project (যেটা আগে তৈরি করেছেন)
- Platforms: **Android**, **iOS** (Space দিয়ে select)
- এটি automatically তৈরি করবে:
  - ✅ `lib/firebase_options.dart`
  - ✅ `android/app/google-services.json`
  - ✅ `ios/Runner/GoogleService-Info.plist`

### Step 4: SHA-1 Add করুন (Android)

```bash
# Debug SHA-1
cd android
./gradlew signingReport

# Output থেকে SHA1 copy করুন
```

**Firebase Console এ add করুন:**
1. Project Settings → Your apps → Android app
2. **Add fingerprint** → SHA-1 paste → **Save**

**⚠️ Release build এর জন্য আলাদা SHA-1 লাগবে!**

### Step 5: iOS Configuration

**ios/Runner/Info.plist** open করুন:

1. `GoogleService-Info.plist` থেকে **REVERSED_CLIENT_ID** copy করুন
2. `Info.plist` এ add করুন (শেষের `</dict>` এর আগে):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- GoogleService-Info.plist থেকে REVERSED_CLIENT_ID paste করুন -->
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

---

## 📁 Part 3: Reusable Code Structure (Copy এই files গুলো)

### File 1: `lib/services/auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        return null;
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('✅ Successfully signed in: ${userCredential.user?.email}');
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      print('✅ Successfully signed out');
    } catch (e) {
      print('❌ Error signing out: $e');
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      await _googleSignIn.signOut();
      print('✅ Account deleted successfully');
    } catch (e) {
      print('❌ Error deleting account: $e');
      rethrow;
    }
  }

  // Get user token (for backend API calls)
  Future<String?> getIdToken() async {
    try {
      return await currentUser?.getIdToken();
    } catch (e) {
      print('❌ Error getting ID token: $e');
      return null;
    }
  }

  // Refresh token
  Future<String?> refreshToken() async {
    try {
      return await currentUser?.getIdToken(true);
    } catch (e) {
      print('❌ Error refreshing token: $e');
      return null;
    }
  }
}
```

### File 2: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Auth App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: AuthGate(),
    );
  }
}
```

### File 3: `lib/screens/auth_gate.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// Auto-login checker
class AuthGate extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is signed in
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen();
        }

        // Not signed in
        return LoginScreen();
      },
    );
  }
}
```

### File 4: `lib/screens/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in cancelled')),
          );
        }
      }
      // AuthGate will automatically navigate to HomeScreen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon/Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.blue.shade800,
                ),
              ),
              SizedBox(height: 40),

              // Title
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Sign in to continue',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 60),

              // Google Sign-In Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : ElevatedButton(
                        onPressed: _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.g_mobiledata, size: 24);
                              },
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### File 5: `lib/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              // AuthGate will automatically navigate to LoginScreen
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Photo
              CircleAvatar(
                radius: 60,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(Icons.person, size: 60)
                    : null,
              ),
              SizedBox(height: 24),

              // User Name
              Text(
                user?.displayName ?? 'No Name',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              // User Email
              Text(
                user?.email ?? 'No Email',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),

              // User ID (for debugging)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'User ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.uid ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),

              // Sign Out Button
              ElevatedButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                },
                icon: Icon(Icons.logout),
                label: Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 📂 Complete Project Structure

```
my_app/
├── lib/
│   ├── firebase_options.dart          # Auto-generated
│   ├── main.dart                      # ✅ Copy
│   ├── services/
│   │   └── auth_service.dart          # ✅ Copy
│   └── screens/
│       ├── auth_gate.dart             # ✅ Copy
│       ├── login_screen.dart          # ✅ Copy
│       └── home_screen.dart           # ✅ Copy
├── android/
│   └── app/
│       └── google-services.json       # Auto-generated
├── ios/
│   └── Runner/
│       ├── GoogleService-Info.plist   # Auto-generated
│       └── Info.plist                 # Manual edit
├── pubspec.yaml                       # Update dependencies
└── README.md
```

---

## 🔄 নতুন Project এ এই Template Use করার Steps

### Quick Checklist:

```bash
# 1. Flutter project তৈরি করুন
flutter create my_new_project
cd my_new_project

# 2. pubspec.yaml update করুন (dependencies add করুন)

# 3. Flutter packages install করুন
flutter pub get

# 4. FlutterFire configure করুন
flutterfire configure

# 5. SHA-1 generate এবং Firebase এ add করুন
cd android && ./gradlew signingReport

# 6. iOS Info.plist update করুন (URL Scheme add করুন)

# 7. Reusable files copy করুন
# - lib/services/auth_service.dart
# - lib/screens/auth_gate.dart
# - lib/screens/login_screen.dart
# - lib/screens/home_screen.dart
# - lib/main.dart update করুন

# 8. Run করুন
flutter run
```

---

## 🎯 এক নজরে পুরো Process

| Step | Command/Action | কতবার লাগবে |
|------|---------------|-------------|
| Firebase CLI install | `npm install -g firebase-tools` | **একবার (globally)** |
| FlutterFire CLI install | `dart pub global activate flutterfire_cli` | **একবার (globally)** |
| Firebase project create | Firebase Console এ | **প্রতি app এ একবার** |
| Google Sign-In enable | Firebase Console → Authentication | **প্রতি Firebase project এ একবার** |
| Flutter project create | `flutter create my_app` | **প্রতিবার** |
| Dependencies add | pubspec.yaml edit | **প্রতিবার** |
| Firebase configure | `flutterfire configure` | **প্রতিবার** |
| SHA-1 add | `gradlew signingReport` → Firebase Console | **প্রতিবার (Debug + Release)** |
| iOS Info.plist edit | Manual | **প্রতিবার** |
| Reusable code copy | Copy করুন | **প্রতিবার** |

---

## 💡 Pro Tips

### 1. Multiple Projects এর জন্য:

**Development:**
- Firebase Project: `myapp-dev`
- Package: `com.example.myapp.dev`

**Production:**
- Firebase Project: `myapp-prod`
- Package: `com.example.myapp`

### 2. Template Repository তৈরি করুন:

```bash
# GitHub এ একটা template repo বানান
git clone https://github.com/yourusername/flutter-google-auth-template
cd flutter-google-auth-template

# শুধু reusable code রাখুন, Firebase config রাখবেন না
```

### 3. Environment Variables (Advanced):

```dart
// lib/config/env.dart
class Env {
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'my-app-dev',
  );
}
```

---

## 🐛 Common Issues

### Issue 1: "PlatformException(sign_in_failed)"
**Fix:**
```bash
# SHA-1 re-generate করুন
cd android && ./gradlew signingReport

# Firebase Console এ add করুন
# google-services.json re-download করুন
flutterfire configure
```

### Issue 2: iOS build fails
**Fix:**
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
```

### Issue 3: "User not found" error
**Fix:**
- Firebase Console → Authentication → Users tab check করুন
- Sign-in method Google enabled আছে কিনা check করুন

---

## 🔐 Security Checklist

**❌ Git এ commit করবেন না:**
```gitignore
# .gitignore এ add করুন
google-services.json
GoogleService-Info.plist
firebase_options.dart
*.keystore
*.jks
.env
```

**✅ করণীয়:**
- Production আর Development আলাদা Firebase project
- Release keystore secure জায়গায় রাখুন
- API keys environment variables এ রাখুন

---

## 📚 Resources

- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Google Sign-In Plugin](https://pub.dev/packages/google_sign_in)
- [Firebase Auth](https://firebase.google.com/docs/auth)

---

এই template follow করলে **10-15 মিনিটে** যেকোনো নতুন Flutter project এ Google Authentication setup করতে পারবেন! 🚀