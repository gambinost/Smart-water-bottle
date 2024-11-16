import 'package:firebase_core/firebase_core.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDwaV1aIhjuZ2fRC_JVGi1eptT2XXA1ljQ",
        authDomain: "smart-bottle-cd2e5.firebaseapp.com",
        projectId: "smart-bottle-cd2e5",
        storageBucket: "smart-bottle-cd2e5.appspot.com",
        messagingSenderId: "638693890651",
        appId: "1:638693890651:web:b0546bf130d2b2e2973d7e",
      ),
    );
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
}
