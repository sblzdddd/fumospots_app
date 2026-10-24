# Flutter embedding. Plugin AARs also ship their own consumer rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Flutter references Play Core for deferred components even when the app does not use them.
-dontwarn com.google.android.play.core.**
