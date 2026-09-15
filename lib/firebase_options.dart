// Client configuration from the owner-downloaded Firebase registrations.
// These are public client identifiers, never administrative credentials.
import 'package:firebase_core/firebase_core.dart';

abstract final class AppFirebaseOptions {
  static const android = FirebaseOptions(
    apiKey: "AIzaSyB-N2MLyOuq4hxUjkj3fZDUezqfuu57tSg",
    appId: "1:849024951967:android:37876bfb5e25493666a4aa",
    messagingSenderId: "849024951967",
    projectId: "maintainiac-aafec",
    storageBucket: "maintainiac-aafec.firebasestorage.app",
  );
  static const ios = FirebaseOptions(
    apiKey: "AIzaSyCxvbBLjNVO_LfYNARbEO-y-L0ttfhpY_g",
    appId: "1:849024951967:ios:6538beb94d287bd666a4aa",
    messagingSenderId: "849024951967",
    projectId: "maintainiac-aafec",
    storageBucket: "maintainiac-aafec.firebasestorage.app",
    iosBundleId: "com.tameyourbiz.app",
    iosClientId:
        "849024951967-n48029k7i6tddfaqobuqalb76i681hcl.apps.googleusercontent.com",
  );
}
