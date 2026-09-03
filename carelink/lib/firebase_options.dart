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
    apiKey: 'dummy_android_key',
    appId: 'dummy_android_app_id',
    messagingSenderId: 'dummy_sender_id',
    projectId: 'dummy_project',
    storageBucket: 'dummy_project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy_ios_key',
    appId: 'dummy_ios_app_id',
    messagingSenderId: 'dummy_sender_id',
    projectId: 'dummy_project',
    storageBucket: 'dummy_project.appspot.com',
    iosBundleId: 'com.example.carelink',
  );
}
