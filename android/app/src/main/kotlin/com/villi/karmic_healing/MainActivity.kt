package com.villi.karmic_healing

import android.content.pm.ActivityInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// A fragment activity rather than a plain one: the biometric prompt the app lock
// puts up is a fragment, and AndroidX has nowhere to attach it otherwise.
class MainActivity : FlutterFragmentActivity() {
    // Which way round the app is allowed to be held, decided before the first
    // frame is drawn.
    //
    // A phone is drawn for one hand holding it upright and has no landscape
    // layout to turn into; a tablet is wide enough on its side to hold every
    // screen and turns with the device. Dart says the same thing again in
    // `OrientationPolicy`, and has the last word on a foldable, whose smallest
    // width changes in the hand — but by then a window has been laid out, and
    // an activity that opened portrait on a landscape tablet has already been
    // letterboxed into a phone-shaped column with black down both sides. So the
    // choice is made here, where it can still be made in time.
    //
    // The manifest cannot make it: its attributes are resolved when the package
    // is parsed, with no device configuration to hand, so a `sw600dp` qualifier
    // on the value would never be read.
    override fun onCreate(savedInstanceState: Bundle?) {
        requestedOrientation =
            if (resources.configuration.smallestScreenWidthDp < TABLET_SMALLEST_WIDTH_DP) {
                ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
            } else {
                ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
            }
        super.onCreate(savedInstanceState)
    }

    private companion object {
        // The width at which Android itself starts calling a screen a tablet.
        const val TABLET_SMALLEST_WIDTH_DP = 600
    }
}
