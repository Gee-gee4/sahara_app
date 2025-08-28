# Keep all Telpo SDK classes
-keep class com.telpo.** { *; }
-keepclassmembers class com.telpo.** { *; }

# Keep native methods and JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep reflection bypass classes
-keep class org.chickenhook.** { *; }
-keepclassmembers class org.chickenhook.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keepclassmembers class io.flutter.** { *; }

# Keep Google Play Core classes (fixes the R8 error)
-keep class com.google.android.play.** { *; }
-keepclassmembers class com.google.android.play.** { *; }

# Keep classes with @Keep annotation
-keep class androidx.annotation.Keep
-keep @androidx.annotation.Keep class * {*;}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <init>(...);
}

# Don't warn about missing Google Play classes
-dontwarn com.google.android.play.**

# Prevent obfuscation of classes with native methods
-keepclasseswithmembers class * {
    public static native <methods>;
}