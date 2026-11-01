import 'package:firebase_core/firebase_core.dart';

/// Values are injected by CI using --dart-define-from-file=firebase-config.json.
/// Do not commit real project credentials to the repository.
class DefaultFirebaseOptions {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static bool get isConfigured =>
      apiKey.isNotEmpty && appId.isNotEmpty &&
      messagingSenderId.isNotEmpty && projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}
