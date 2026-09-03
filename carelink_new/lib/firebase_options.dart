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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'dummy_web_key',
    appId: 'dummy_web_app_id',
    messagingSenderId: 'dummy_sender_id',
    projectId: 'dummy_project',
    authDomain: 'dummy_project.firebaseapp.com',
    storageBucket: 'dummy_project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB3MHM9qcMGqSXuzIhPOHTM5p2eYeSqG7c',
    appId: '1:1053001444815:android:2423f92978465b09a476ba',
    messagingSenderId: '1053001444815',
    projectId: 'sih2026-27',
    storageBucket: 'sih2026-27.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzFajzDnW4ygKq5SrPkBtkKgFbia3fjFQ',
    appId: '1:1053001444815:ios:2de51e55510173dfa476ba',
    messagingSenderId: '1053001444815',
    projectId: 'sih2026-27',
    storageBucket: 'sih2026-27.firebasestorage.app',
    iosBundleId: 'com.outliers.carelinkNew',
  );
}
