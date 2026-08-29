// firebase_options.dart
// android + web are already configured for this project.
// iOS/macOS still have placeholder values below - run `flutterfire configure`
// if you need to build for those platforms.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Replace every 'YOUR_...' value with the real values from your
  // Firebase project settings (Project Settings → Your apps → SDK setup).

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBQ7tX3IRdKwo2gdqoKle39upRiWwO_d3I',
    appId: '1:958612893819:web:4006b782ab5daa384df2de',
    messagingSenderId: '958612893819',
    projectId: 'medibuddy-aff20',
    authDomain: 'medibuddy-aff20.firebaseapp.com',
    storageBucket: 'medibuddy-aff20.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgT30sHMPe6nXFKkiOpCVO4Nxw-lBI6IU',
    appId: '1:958612893819:android:cbea58b174533de64df2de',
    messagingSenderId: '958612893819',
    projectId: 'medibuddy-aff20',
    storageBucket: 'medibuddy-aff20.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.medibuddy',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    iosBundleId: 'com.example.medibuddy',
  );
}
