package com.karmichealing.karmic_healing_flutter

import io.flutter.embedding.android.FlutterFragmentActivity

// A fragment activity rather than a plain one: the biometric prompt the app lock
// puts up is a fragment, and AndroidX has nowhere to attach it otherwise.
class MainActivity : FlutterFragmentActivity()
