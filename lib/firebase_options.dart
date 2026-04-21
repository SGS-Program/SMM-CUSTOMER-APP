
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCykqmZ47rznTlU6bKbsIbGwz1xhxJUm_I',
    appId: '1:356902458944:web:d96cbddbf7876c261931a5',
    messagingSenderId: '356902458944',
    projectId: 'smm-service-557d6',
    authDomain: 'smm-service-557d6.firebaseapp.com',
    storageBucket: 'smm-service-557d6.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC0VVqMg-dmdkZ14H5LYFAl_rex6k7nF0I',
    appId: '1:356902458944:android:5187fdc23e5dc5b61931a5',
    messagingSenderId: '356902458944',
    projectId: 'smm-service-557d6',
    storageBucket: 'smm-service-557d6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUDGD4iLdwAYDmkBpEaaY_hLUmxubxb9g',
    appId: '1:356902458944:ios:5e68ed68568d9f3c1931a5',
    messagingSenderId: '356902458944',
    projectId: 'smm-service-557d6',
    storageBucket: 'smm-service-557d6.firebasestorage.app',
    iosClientId: '356902458944-kenuggliv4ol152u24k82share816vgc.apps.googleusercontent.com',
    iosBundleId: 'com.example.customerSmm',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDUDGD4iLdwAYDmkBpEaaY_hLUmxubxb9g',
    appId: '1:356902458944:ios:5e68ed68568d9f3c1931a5',
    messagingSenderId: '356902458944',
    projectId: 'smm-service-557d6',
    storageBucket: 'smm-service-557d6.firebasestorage.app',
    iosClientId: '356902458944-kenuggliv4ol152u24k82share816vgc.apps.googleusercontent.com',
    iosBundleId: 'com.example.customerSmm',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCykqmZ47rznTlU6bKbsIbGwz1xhxJUm_I',
    appId: '1:356902458944:web:88ef4bd42b34cd0f1931a5',
    messagingSenderId: '356902458944',
    projectId: 'smm-service-557d6',
    authDomain: 'smm-service-557d6.firebaseapp.com',
    storageBucket: 'smm-service-557d6.firebasestorage.app',
  );
}
