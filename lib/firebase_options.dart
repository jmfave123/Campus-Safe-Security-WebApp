import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD1hd_ArzSNufP2RiehrN4qqLVoLoOs0Xs',
    appId: '1:347945595192:web:6378f47f685c443c4ed1cd',
    messagingSenderId: '347945595192',
    projectId: 'campussafe-capstone',
    authDomain: 'campussafe-capstone.firebaseapp.com',
    databaseURL:
        'https://campussafe-capstone-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'campussafe-capstone.appspot.com',
    measurementId: 'G-JC184VLS9K',
  );

  // For web-only app, currentPlatform just returns web
  static FirebaseOptions get currentPlatform => web;
}
