package com.programmernexus.lifeque

/**
 * Where a home-screen widget should take you when tapped.
 *
 * The Dart side reads this back off the launch intent and pushes the matching
 * route, so a widget lands on the screen it is about instead of on whichever
 * page the user happens to have set as their home.
 */
object WidgetRoutes {
    const val SCHEME = "lifeque"
    const val PRAYER = "$SCHEME://prayer-times"
}
