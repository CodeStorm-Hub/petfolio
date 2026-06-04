import 'package:flutter_test/flutter_test.dart';
import 'package:petfolio/core/firebase/fcm_message_router.dart';

void main() {
  group('FcmMessageRouter', () {
    test('uses explicit route when provided', () {
      expect(
        FcmMessageRouter.routeFromData({'route': '/care'}),
        '/care',
      );
    });

    test('maps chat_message to thread path', () {
      expect(
        FcmMessageRouter.routeFromData({
          'type': 'chat_message',
          'thread_id': 'abc-123',
        }),
        '/matching/chat/abc-123',
      );
    });

    test('maps like to post when post_id present', () {
      expect(
        FcmMessageRouter.routeFromData({
          'type': 'like',
          'post_id': 'post-1',
        }),
        '/social/post/post-1',
      );
    });

    test('maps order to buyer order detail', () {
      expect(
        FcmMessageRouter.routeFromData({
          'type': 'order',
          'order_id': 'ord-9',
        }),
        '/profile/orders/ord-9',
      );
    });

    test('maps kyc_approved to seller dashboard', () {
      expect(
        FcmMessageRouter.routeFromData({'type': 'kyc_approved'}),
        '/seller',
      );
    });
  });
}
