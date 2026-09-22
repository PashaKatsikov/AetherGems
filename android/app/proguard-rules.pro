-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

-dontwarn com.google.android.play.core.**

-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**

-keep class androidx.security.crypto.** { *; }

-keepclasseswithmembernames class * {
    native <methods>;
}

-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
}
