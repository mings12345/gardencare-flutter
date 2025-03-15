# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Prevent R8 from removing Firebase Instance ID classes
-keep class com.google.firebase.iid.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.FirebaseInstanceId { *; }
-keep class com.google.firebase.iid.InstanceIdResult { *; }

# Keep Pusher classes
-keep class com.pusher.pushnotifications.** { *; }

# Keep Play Core classes (required for Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Additional rules for Firebase and Pusher
-keep class com.google.firebase.** { *; }
-keep class com.pusher.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class com.google.firebase.messaging.RemoteMessage { *; }
-keep class com.google.firebase.messaging.RemoteMessage$Notification { *; }