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
Running Gradle task 'assembleDebug'...                             21.6s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...        1,948ms
I/FlutterActivityAndFragmentDelegate(13296): If you are attempting to set --enable-dart-profiling via Intent extras to launch a Flutter component outside of using the Flutter CLI, note that support for setting engine flags on Android via Intent will soon be dropped; see https://github.com/flutter/flutter/issues/180686 for more information on this breaking change. To migrate, set --enable-dart-profiling or any other flags specified via Intent extras on the command line instead or see https://github.com/flutter/flutter/blob/main/docs/engine/Flutter-Android-Engine-Flags.md for alternative methods.
D/FlutterJNI(13296): Beginning load of flutter...
D/FlutterJNI(13296): flutter (null) was loaded normally!
I/flutter (13296): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
D/FlutterGeolocator(13296): Attaching Geolocator to activity
D/FlutterRenderer(13296): Width is zero. 0,0
D/FlutterGeolocator(13296): Creating service.
D/FlutterGeolocator(13296): Binding to location service.
D/WindowOnBackDispatcher(13296): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@671fe96
I/WindowExtensionsImpl(13296): Initializing Window Extensions, vendor API level=10, activity embedding enabled=true
W/UiContextUtils(13296): Requested context is a non-UI Context. Creating a UI-Context with display: 0. Context: Context=android.app.Application@9cf11e2, of which baseContext=android.app.ContextImpl@4c470b3
I/xample.petfolio(13296): Compiler allocated 5250KB to compile void android.view.ViewRootImpl.performTraversals(long)
D/VRI[MainActivity](13296): WindowInsets changed: 1080x2424 statusBars:[0,142,0,0] navigationBars:[0,0,0,63] mandatorySystemGestures:[0,174,0,84]
D/FlutterRenderer(13296): Width is zero. 0,0
I/Surface (13296): Creating surface for consumer unnamed-13296-0 with slotExpansion=1 for 64 slots
I/Surface (13296): Creating surface for consumer VRI[MainActivity]#0(BLAST Consumer)0 with slotExpansion=1 for 64 slots
D/FlutterJNI(13296): Sending viewport metrics to the engine.
I/Surface (13296): Creating surface for consumer unnamed-13296-1 with slotExpansion=1 for 64 slots
I/Surface (13296): Creating surface for consumer a518fa5 SurfaceView[com.example.petfolio/com.example.petfolio.MainActivity]#1(BLAST Consumer)1 with slotExpansion=1 for 64 slots
Syncing files to device sdk gphone16k x86 64...                    158ms

Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on sdk gphone16k x86 64 is available at: http://127.0.0.1:59006/M3CJt_KGSlU=/
The Flutter DevTools debugger and profiler on sdk gphone16k x86 64 is available at:
http://127.0.0.1:59006/M3CJt_KGSlU=/devtools/?uri=ws://127.0.0.1:59006/M3CJt_KGSlU=/ws
D/FlutterGeolocator(13296): Geolocator foreground service connected
D/FlutterGeolocator(13296): Initializing Geolocator services
D/FlutterGeolocator(13296): Flutter engine connected. Connected engine count 1
I/HWUI    (13296): Using FreeType backend (prop=Auto)
I/Choreographer(13296): Skipped 40 frames!  The application may be doing too much work on its main thread.
I/xample.petfolio(13296): hiddenapi: Accessing hidden method Landroid/os/SystemProperties;->addChangeCallback(Ljava/lang/Runnable;)V (runtime_flags=0, domain=platform, api=unsupported) from Landroidx/compose/ui/platform/AndroidComposeView$Companion; (domain=app, TargetSdkVersion=36) using reflection: allowed
D/WindowLayoutComponentImpl(13296): Register WindowLayoutInfoListener on Context=com.example.petfolio.MainActivity@bbce388, of which baseContext=android.app.ContextImpl@c56e043
I/Choreographer(13296): Skipped 42 frames!  The application may be doing too much work on its main thread.
I/flutter (13296): supabase.supabase_flutter: INFO: ***** Supabase init completed ***** 
D/FlutterJNI(13296): Sending viewport metrics to the engine.
I/Choreographer(13296): Skipped 81 frames!  The application may be doing too much work on its main thread.
D/InsetsController(13296): hide(ime())
I/ImeTracker(13296): com.example.petfolio:dabbf2db: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/ProfileInstaller(13296): Installing profile for com.example.petfolio
