// Konfigurasi Firebase untuk project skripsi "mustika-ayu-catering".
//
// Dibuat manual dari Firebase Console (Project settings > Your apps),
// karena FlutterFire CLI belum terpasang. Isinya pengenal project,
// bukan kata sandi, sehingga boleh di-commit.
//
// - Android: com.mustikaayu.catering (nilai dari google-services.json)
// - Web    : Mustika Ayu Catering Web

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Aplikasi ini hanya dikonfigurasi untuk Android dan web.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCSQ_khYt95ts31ZGUFTNebmruNsUjLVmE',
    appId: '1:858962587231:web:6ff1117208c0536e9875ea',
    messagingSenderId: '858962587231',
    projectId: 'mustika-ayu-catering',
    authDomain: 'mustika-ayu-catering.firebaseapp.com',
    storageBucket: 'mustika-ayu-catering.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyArV6x1Y5VhUe8wMmcHgJqw65YqHkRfPVk',
    appId: '1:858962587231:android:955798138ca147349875ea',
    messagingSenderId: '858962587231',
    projectId: 'mustika-ayu-catering',
    storageBucket: 'mustika-ayu-catering.firebasestorage.app',
  );
}
