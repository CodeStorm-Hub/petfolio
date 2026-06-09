import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Synthetic Spring plan — implementation contract', () {
    test('Phase 1: router split into per-feature route files', () {
      expect(File('lib/core/navigation/app_shell_routes.dart').existsSync(), isTrue);
      expect(File('lib/core/navigation/router_notifier.dart').existsSync(), isTrue);
      expect(File('lib/core/navigation/router_error_screen.dart').existsSync(), isTrue);
      for (final feature in [
        'auth',
        'care',
        'social',
        'matching',
        'marketplace',
        'pet_profile',
        'appointments',
        'communities',
        'admin',
      ]) {
        final routes = Directory('lib/features/$feature')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('_routes.dart'))
            .toList();
        expect(routes, isNotEmpty, reason: 'Expected *_routes.dart under $feature');
      }
    });

    test('Phase 1: secure storage and DCM config present', () {
      expect(File('lib/core/services/secure_storage_service.dart').existsSync(), isTrue);
      expect(File('dcm.yaml').existsSync(), isTrue);
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('flutter_secure_storage'), isTrue);
    });

    test('Phase 2: M3 expressive, skeleton, tutorial, gamification', () {
      final theme = File('lib/core/theme/app_theme.dart').readAsStringSync();
      expect(theme.contains('NavigationBarTheme'), isTrue);

      expect(File('lib/core/widgets/skeleton_loader.dart').existsSync(), isTrue);
      expect(File('lib/core/widgets/app_tutorial_overlay.dart').existsSync(), isTrue);

      final gamified = File('lib/features/care/presentation/widgets/gamified_care_ui.dart')
          .readAsStringSync();
      expect(gamified.contains('ConfettiWidget') || gamified.contains('confetti'), isTrue);

      final matching = File('lib/features/matching/presentation/screens/matching_screen.dart')
          .readAsStringSync();
      expect(matching.contains('HapticFeedback'), isTrue);

      final social = File('lib/features/social/presentation/screens/social_screen.dart')
          .readAsStringSync();
      expect(social.contains('RepaintBoundary'), isTrue);
    });

    test('Phase 3: image compression and cursor pagination', () {
      final mediaPicker = File('lib/core/platform/media_picker_io.dart').readAsStringSync();
      expect(mediaPicker.contains('FlutterImageCompress'), isTrue);

      final productList =
          File('lib/features/marketplace/presentation/controllers/product_list_controller.dart')
              .readAsStringSync();
      expect(productList.contains('_cursorCreatedAt'), isTrue);
      expect(productList.contains('_cursorId'), isTrue);
    });

    test('Phase 4: vitals, reviews, appointments, walk tracking, communities', () {
      expect(File('lib/features/care/presentation/widgets/vitals_chart_widget.dart').existsSync(),
          isTrue);
      expect(File('lib/features/marketplace/presentation/widgets/star_rating_widget.dart')
          .existsSync(), isTrue);
      expect(File('lib/features/appointments/presentation/screens/appointments_screen.dart')
          .existsSync(), isTrue);
      expect(File('lib/features/care/presentation/screens/walk_tracking_screen.dart').existsSync(),
          isTrue);
      expect(Directory('lib/features/communities').existsSync(), isTrue);

      final checkout =
          File('lib/features/marketplace/presentation/controllers/checkout_controller.dart')
              .readAsStringSync();
      expect(checkout.contains('PaymentSheetGooglePay'), isTrue);
      expect(checkout.contains('PaymentSheetApplePay'), isTrue);
    });

    test('Phase 5: security tests and edge function for PaymentIntent', () {
      expect(File('test/security/stripe_client_contract_test.dart').existsSync(), isTrue);
      expect(File('test/security/rls_migration_contract_test.dart').existsSync(), isTrue);
      expect(File('supabase/functions/create-payment-intent/index.ts').existsSync(), isTrue);

      final orderRepo = File('lib/features/marketplace/data/repositories/order_repository.dart')
          .readAsStringSync();
      expect(orderRepo.contains('create-payment-intent'), isTrue);
      expect(orderRepo.contains('mapAndThrowCheckoutRpcException'), isTrue);
    });

    test('Remainder: chat read receipts, story reactions, product card ratings', () {
      final chatDs =
          File('lib/features/matching/data/datasources/matching_supabase_data_source.dart')
              .readAsStringSync();
      expect(chatDs.contains('markMessagesAsRead'), isTrue);

      final migration =
          File('supabase/migrations/20260608140000_chat_read_receipts_story_reactions.sql');
      expect(migration.existsSync(), isTrue);
      final migrationSql = migration.readAsStringSync().toLowerCase();
      expect(migrationSql.contains('story_reactions'), isTrue);
      expect(migrationSql.contains('mark read'), isTrue);

      final productCard =
          File('lib/features/marketplace/presentation/widgets/product_card.dart').readAsStringSync();
      expect(productCard.contains('StarRatingWidget') || productCard.contains('rating'), isTrue);
    });

    test('Network image cache recovery widget exists', () {
      expect(File('lib/core/widgets/petfolio_network_image.dart').existsSync(), isTrue);
    });

    test('Integration and golden test entrypoints exist', () {
      expect(File('integration_test/auth_care_flow_test.dart').existsSync(), isTrue);
      expect(File('test/core/theme/app_theme_golden_test.dart').existsSync(), isTrue);
    });
  });
}
