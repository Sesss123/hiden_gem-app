# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# Firebase & Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**

# Hive & Database
-keep class hive.** { *; }
-keep class com.hivedb.** { *; }
-keep class io.hive.** { *; }
-keep class com.hidden.gems.hidden_gems_sl.data.models.** { *; }
-dontwarn net.sqlcipher.**

# AndroidX & Lifecycle
-keep class androidx.lifecycle.** { *; }
-keep class androidx.annotation.** { *; }

# JNI & Optimization
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enable obfuscation and shrinking for production security
-repackageclasses ''
-allowaccessmodification
-printmapping mapping.txt

# Keep attributes for reflection
-keepattributes Signature,Exceptions,SourceFile,LineNumberTable,*Annotation*,EnclosingMethod,InnerClasses

# Rules for grpc and okhttp missing classes triggered by R8
-dontwarn io.grpc.**
-dontwarn com.squareup.okhttp.**

# ARCore & Sceneform
-keep class com.google.ar.** { *; }
-keep interface com.google.ar.** { *; }
-keep class com.google.ar.sceneform.** { *; }
-keep interface com.google.ar.sceneform.** { *; }
-dontwarn com.google.ar.**
-dontwarn com.google.ar.sceneform.**
-dontwarn com.google.devtools.build.android.desugar.runtime.**
