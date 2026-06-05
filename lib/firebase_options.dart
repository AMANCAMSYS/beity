import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD9nCJGcfIp3p1emZVvawnkC-lC3E5vzmk',
    appId: '1:977923653056:android:49c9fe4b1fd307934d9c25',
    messagingSenderId: '977923653056',
    projectId: 'sawa-5c4e0',
    storageBucket: 'sawa-5c4e0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBdaV70ymnLBOh4lcibFPJ_kWWFac4xXO4',
    appId: '1:977923653056:ios:d893581bbf40f4514d9c25',
    messagingSenderId: '977923653056',
    projectId: 'sawa-5c4e0',
    storageBucket: 'sawa-5c4e0.firebasestorage.app',
    iosBundleId: 'com.sawa.sawa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBdaV70ymnLBOh4lcibFPJ_kWWFac4xXO4',
    appId: '1:977923653056:ios:d893581bbf40f4514d9c25',
    messagingSenderId: '977923653056',
    projectId: 'sawa-5c4e0',
    storageBucket: 'sawa-5c4e0.firebasestorage.app',
    iosBundleId: 'com.sawa.sawa',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjzY6gV7MQ30zNXyMKUECvqiiYwaYFv-8',
    appId: '1:977923653056:web:ee82acc21f07eacd4d9c25',
    messagingSenderId: '977923653056',
    projectId: 'sawa-5c4e0',
    authDomain: 'sawa-5c4e0.firebaseapp.com',
    storageBucket: 'sawa-5c4e0.firebasestorage.app',
    measurementId: 'G-WXVLKJLDMJ',
  );
}
