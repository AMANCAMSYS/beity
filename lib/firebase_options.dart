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
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBO_SST1Zs7Ae6Ww4Rfy5t8Sc8gh66FpCU',
    appId: '1:629950526379:android:d0a6305baf31bbd1af58ee',
    messagingSenderId: '629950526379',
    projectId: 'beity-ad796',
    storageBucket: 'beity-ad796.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAFcQd5rcAT8Ci4LtUOBrtC71MDVOmDam0',
    appId: '1:629950526379:ios:71616fd2d0156ce6af58ee',
    messagingSenderId: '629950526379',
    projectId: 'beity-ad796',
    storageBucket: 'beity-ad796.firebasestorage.app',
    iosBundleId: 'com.beity.beity',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAFcQd5rcAT8Ci4LtUOBrtC71MDVOmDam0',
    appId: '1:629950526379:ios:71616fd2d0156ce6af58ee',
    messagingSenderId: '629950526379',
    projectId: 'beity-ad796',
    storageBucket: 'beity-ad796.firebasestorage.app',
    iosBundleId: 'com.beity.beity',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBO_SST1Zs7Ae6Ww4Rfy5t8Sc8gh66FpCU',
    appId: '1:629950526379:web:d0a6305baf31bbd1af58ee',
    messagingSenderId: '629950526379',
    projectId: 'beity-ad796',
    storageBucket: 'beity-ad796.firebasestorage.app',
    authDomain: 'beity-ad796.firebaseapp.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBO_SST1Zs7Ae6Ww4Rfy5t8Sc8gh66FpCU',
    appId: '1:629950526379:windows:d0a6305baf31bbd1af58ee',
    messagingSenderId: '629950526379',
    projectId: 'beity-ad796',
    storageBucket: 'beity-ad796.firebasestorage.app',
  );
}
