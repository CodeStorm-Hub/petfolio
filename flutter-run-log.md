PS G:\GitHub\petfolio> flutter run --dart-define-from-file=.env
Launching lib\main.dart on sdk gphone16k x86 64 in debug mode...
WARNING: Your Android app project: app located at: G:\GitHub\petfolio\android\app\build.gradle.kts
applies the Kotlin Gradle Plugin, which will cause build failures in future versions of Flutter.
Please migrate your app to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers

WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): image_picker_android, share_plus, shared_preferences_android, stripe_android, url_launcher_android
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.      
If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing        
an issue against a plugin: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors

If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
warning: [options] source value 8 is obsolete and will be removed in a future release
warning: [options] target value 8 is obsolete and will be removed in a future release
warning: [options] To suppress warnings about obsolete options, use -Xlint:-options.
3 warnings
Running Gradle task 'assembleDebug'...                             51.4s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...          996ms
I/FlutterActivityAndFragmentDelegate(14767): If you are attempting to set --enable-dart-profiling via Intent extras to launch a Flutter component outside of using the Flutter CLI, note that support for setting engine flags on Android via Intent will soon be dropped; see https://github.com/flutter/flutter/issues/180686 for more information on this breaking change. To migrate, set --enable-dart-profiling or any other flags specified via Intent extras on the command line instead or see https://github.com/flutter/flutter/blob/main/docs/engine/Flutter-Android-Engine-Flags.md for alternative methods.
D/FlutterJNI(14767): Beginning load of flutter...
D/FlutterJNI(14767): flutter (null) was loaded normally!
I/flutter (14767): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
D/FlutterGeolocator(14767): Attaching Geolocator to activity
D/FlutterRenderer(14767): Width is zero. 0,0
D/FlutterGeolocator(14767): Creating service.
D/FlutterGeolocator(14767): Binding to location service.
D/WindowOnBackDispatcher(14767): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@671fe96
I/WindowExtensionsImpl(14767): Initializing Window Extensions, vendor API level=10, activity embedding enabled=true
I/xample.petfolio(14767): Compiler allocated 5250KB to compile void android.view.ViewRootImpl.performTraversals(long)
W/UiContextUtils(14767): Requested context is a non-UI Context. Creating a UI-Context with display: 0. Context: Context=android.app.Application@9cf11e2, of which baseContext=android.app.ContextImpl@4c470b3       
D/VRI[MainActivity](14767): WindowInsets changed: 1080x2424 statusBars:[0,142,0,0] navigationBars:[0,0,0,63] mandatorySystemGestures:[0,174,0,84]
D/FlutterRenderer(14767): Width is zero. 0,0
I/Surface (14767): Creating surface for consumer unnamed-14767-0 with slotExpansion=1 for 64 slots        
I/Surface (14767): Creating surface for consumer VRI[MainActivity]#0(BLAST Consumer)0 with slotExpansion=1 for 64 slots
D/FlutterJNI(14767): Sending viewport metrics to the engine.
I/Surface (14767): Creating surface for consumer unnamed-14767-1 with slotExpansion=1 for 64 slots
I/Surface (14767): Creating surface for consumer a518fa5 SurfaceView[com.example.petfolio/com.example.petfolio.MainActivity]#1(BLAST Consumer)1 with slotExpansion=1 for 64 slots
D/FlutterGeolocator(14767): Geolocator foreground service connected
D/FlutterGeolocator(14767): Initializing Geolocator services
D/FlutterGeolocator(14767): Flutter engine connected. Connected engine count 1
I/Choreographer(14767): Skipped 44 frames!  The application may be doing too much work on its main thread.
I/HWUI    (14767): Using FreeType backend (prop=Auto)
I/xample.petfolio(14767): hiddenapi: Accessing hidden method Landroid/os/SystemProperties;->addChangeCallback(Ljava/lang/Runnable;)V (runtime_flags=0, domain=platform, api=unsupported) from Landroidx/compose/ui/platform/AndroidComposeView$Companion; (domain=app, TargetSdkVersion=36) using reflection: allowed
D/WindowLayoutComponentImpl(14767): Register WindowLayoutInfoListener on Context=com.example.petfolio.MainActivity@bbce388, of which baseContext=android.app.ContextImpl@b6a02b5
I/Choreographer(14767): Skipped 44 frames!  The application may be doing too much work on its main thread.
Syncing files to device sdk gphone16k x86 64...                    171ms

Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on sdk gphone16k x86 64 is available at: http://127.0.0.1:54386/Ych0_YBW-GQ=/
The Flutter DevTools debugger and profiler on sdk gphone16k x86 64 is available at:
http://127.0.0.1:54386/Ych0_YBW-GQ=/devtools/?uri=ws://127.0.0.1:54386/Ych0_YBW-GQ=/ws
I/flutter (14767): supabase.supabase_flutter: INFO: ***** Supabase init completed ***** 
D/FlutterJNI(14767): Sending viewport metrics to the engine.
I/Choreographer(14767): Skipped 85 frames!  The application may be doing too much work on its main thread.
D/InsetsController(14767): hide(ime())
I/ImeTracker(14767): com.example.petfolio:9b0c77f3: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/ProfileInstaller(14767): Installing profile for com.example.petfolio
I/xample.petfolio(14767): Background concurrent mark compact GC freed 6145KB AllocSpace bytes, 20(832KB) LOS objects, 49% free, 5194KB/10MB, paused 906us,5.160ms total 16.410ms
