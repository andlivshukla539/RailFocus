# ═══════════════════════════════════════════════════════════════
# RAILFOCUS PROGUARD RULES
# Keeps required classes while stripping unused code
# ═══════════════════════════════════════════════════════════════

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Fonts
-keep class com.google.android.gms.** { *; }

# Hive
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# AudioPlayers
-keep class xyz.luan.audioplayers.** { *; }

# Notifications
-keep class com.dexterous.** { *; }

# General
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-dontwarn com.google.**
-dontwarn javax.**
