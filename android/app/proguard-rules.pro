# Flutter specific ProGuard rules

# Keep Flutter app entry points
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin Metadata
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class tm.ranjith.trackmywork.**$$serializer { *; }
-keepclassmembers class tm.ranjith.trackmywork.** {
    *** Companion;
}
-keepclasseswithmembers class tm.ranjith.trackmywork.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep SharedPreferences
-keep class androidx.preference.Preference { *; }

# Keep our app classes
-keep class tm.ranjith.trackmywork.** { *; }

# Keep Play Core library classes
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.** { *; }

# Aggressive optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove logging code
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Remove unused code
-dontwarn android.support.**
-dontwarn androidx.**
-dontwarn com.google.android.material.**
-dontwarn org.xmlpull.v1.**

# Uncomment for release build
# -printmapping mapping.txt
