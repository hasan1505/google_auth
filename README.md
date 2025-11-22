# google_login
আমি তোমার জন্য **একটা প্রস্তুতকৃত `README.md` লিখে দিচ্ছি**, যেখানে থাকবে—

✔ Google OAuth Setup (Android + iOS)
✔ Firebase Console setup
✔ SHA-1/SHA-256
✔ GoogleService-Info.plist
✔ google-services.json
✔ Flutter Configuration
✔ Sign in Code (reusable in all projects)
✔ নিরাপদ Token handling



### **Step 1 — Firebase Console**

👉 [https://console.firebase.google.com/](https://console.firebase.google.com/)

* “Add project”
* Project name দাও → Continue
* Analytics off করতে পারো → Create

---

# ## 2️⃣ Android Setup

### **Step 1 — SHA-1 & SHA-256 generate (required)**

#### macOS / Linux:

```sh
./gradlew signingReport
```

SHA-1 & SHA-256 কপি রাখো।

#### Windows:

```sh
gradlew signingReport
```

---

### **Step 2 — Firebase এ Android App Add**

* Android package name:
  **`com.yourcompany.yourapp`**
* App nickname: optional
* SHA-1 paste করো
* SHA-256 paste করো
* Download **google-services.json**
* এটি রাখো:

```
android/app/google-services.json
```

---

### **Step 3 — android/build.gradle**

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

---

### **Step 4 — android/app/build.gradle**

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
}
```

---

### **Step 5 — Android Manifest**

`android/app/src/main/AndroidManifest.xml` এ যোগ করো:

```xml
<meta-data
    android:name="com.google.android.gms.games.APP_ID"
    android:value="@string/app_id" />

<meta-data
    android:name="com.google.android.gms.version"
    android:value="@integer/google_play_services_version" />
```

---

# ## 3️⃣ iOS Setup

### **Step 1 — iOS App Add**

Firebase Console → Add App → iOS নির্বাচন

* iOS bundle ID:
  **`com.yourcompany.yourapp`**

### **Step 2 — GoogleService-Info.plist ডাউনলোড করো**

এটি রাখো:

```
ios/Runner/GoogleService-Info.plist
```

---

### **Step 3 — iOS Pod Setup**

`ios/Podfile` edit:

```ruby
platform :ios, '12.0'
```

---

### **Step 4 — Xcode Setup**

Xcode → Runner →
TARGETS → Runner →
**Signing & Capabilities →+ Capability → Sign In with Apple + Keychain Sharing (optional)**

---

### **Step 5 — URL Scheme Add**

Xcode → Runner → Info → URL Types → +

`REVERSED_CLIENT_ID` যোগ করো (plist এর ভেতরে থাকে)

---

# ## 4️⃣ Flutter Dependencies

`pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  google_sign_in: ^7.0.0
```

Install:

```sh
flutter pub get
```

---

# ## 5️⃣ Initialize Firebase

`main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

---

# ## 6️⃣ Reusable Google Sign-In Service (Use in All Projects)

`lib/services/google_auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<User?> signIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    return userCredential.user;
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }
}
```

---

# ## 7️⃣ Use in UI (Any Project)

```dart
ElevatedButton(
  onPressed: () async {
    final user = await GoogleAuthService.signIn();
    if (user != null) {
      print("Name: ${user.displayName}");
      print("Email: ${user.email}");
      print("Photo: ${user.photoURL}");
    }
  },
  child: Text("Continue with Google"),
);
```

---

# ## 8️⃣ Send Firebase Token to Backend

```dart
final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
```

Backend receives:

* idToken → verify
* create user if new
* return JWT token
* return user profile

---

# ## 9️⃣ Common Errors

| Error                               | Solution                    |
| ----------------------------------- | --------------------------- |
| SHA-1 mismatch                      | Firebase → Update SHA-1     |
| iOS Google Sign-in not opening      | Add URL Scheme correctly    |
| debug app works but release fails   | Add release SHA-1 & SHA-256 |
| “PlatformException(sign_in_failed)” | Wrong client id             |

---

# ## 🔥 Finished!

এখন তুমি যেকোনো Flutter Project এ Google Auth add করতে পারবে এই README.md দিয়ে।

---

# 👉 তুমি কি চাও আমি তোমার **Firebase Auth + Backend Token System** পুরা project-ready করে দিই?


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# google_auth
