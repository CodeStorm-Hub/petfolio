# PetFolio
PetFolio is a feature-rich, social-commerce platform built specifically for pet owners. It acts as a hybrid between an Instagram-style social network, a Tinder-style pet discovery/matching service (for breeding and playdates), a comprehensive health and daily care tracker, and an e-commerce marketplace for pet products.


flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_51TQvlrPcVRApxzIxJ8RmKYA1WEw7k8zubumbIfsDjRSGgDyAcSU22RhsZRtKIP1lAZ0wtGjpLfzjI4fozMZxGSlo006zuZrbon

---
PS G:\GitHub\petfolio> flutter pub get
Resolving dependencies... 
Because flutter_stripe >=12.6.0 depends on stripe_platform_interface ^12.6.0 which depends on freezed_annotation ^3.1.0,
  flutter_stripe >=12.6.0 requires freezed_annotation ^3.1.0.
So, because petfolio depends on both freezed_annotation ^2.4.4 and flutter_stripe ^12.6.0, version solving failed.


You can try the following suggestion to make the pubspec resolve:
* Consider downgrading your constraint on flutter_stripe: flutter pub add flutter_stripe:^11.5.0
Failed to update packages.
PS G:\GitHub\petfolio> flutter pub get
Resolving dependencies... 
Downloading packages... (1.0s)
  _fe_analyzer_shared 85.0.0 (100.0.0 available)
  analyzer 7.6.0 (13.0.0 available)
  analyzer_plugin 0.13.4 (0.14.9 available)
  build 2.5.4 (4.0.6 available)
  build_config 1.1.2 (1.3.0 available)
  build_resolvers 2.5.4 (3.0.4 available)
  build_runner 2.5.4 (2.15.0 available)
  build_runner_core 9.1.2 (9.3.2 available)
  custom_lint_core 0.7.5 (0.8.2 available)
  custom_lint_visitor 1.0.0+7.7.0 (1.0.0+9.0.0 available)
  dart_style 3.1.1 (3.1.9 available)
  flutter_riverpod 2.6.1 (3.3.1 available)
+ flutter_stripe 11.5.0 (12.6.0 available)
  freezed 2.5.8 (3.2.5 available)
  freezed_annotation 2.4.4 (3.1.0 available)
  go_router 14.8.1 (17.2.3 available)
  google_fonts 6.3.3 (8.1.0 available)
  json_annotation 4.9.0 (4.11.0 available)
  json_serializable 6.9.5 (6.13.2 available)
  matcher 0.12.19 (0.12.20 available)
  meta 1.17.0 (1.18.2 available)
  native_toolchain_c 0.17.6 (0.18.0 available)
  riverpod 2.6.1 (3.2.1 available)
  riverpod_analyzer_utils 0.5.9 (0.5.10 available)
  riverpod_annotation 2.6.1 (4.0.2 available)
  riverpod_generator 2.6.4 (4.0.3 available)
  source_gen 2.0.0 (4.2.3 available)
  source_helper 1.3.7 (1.3.12 available)
+ stripe_android 11.5.0 (12.6.0 available)
+ stripe_ios 11.5.0 (12.6.0 available)
+ stripe_platform_interface 11.5.0 (12.6.0 available)
  test_api 0.7.10 (0.7.12 available)
  vector_math 2.2.0 (2.3.0 available)
Changed 4 dependencies!
33 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
PS G:\GitHub\petfolio> 
---