import 'package:go_router/go_router.dart';

class FcmMessageRouter {
  FcmMessageRouter._();

  static String? routeFromData(Map<String, dynamic> data) {
    final route = data['route'] as String?;
    if (route != null && route.startsWith('/')) return route;

    final type = data['type'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'care_reminder':
        return '/care';
      case 'match':
        return '/matching/inbox';
      case 'chat_message':
        final threadId = data['thread_id'] as String?;
        if (threadId != null && threadId.isNotEmpty) {
          return '/matching/chat/$threadId';
        }
        return '/matching/inbox';
      case 'like':
      case 'comment':
        final postId = data['post_id'] as String?;
        if (postId != null && postId.isNotEmpty) {
          return '/social/post/$postId';
        }
        return '/social/notifications';
      case 'follow':
        return '/social/notifications';
      case 'kyc_approved':
        return '/seller';
      case 'kyc_rejected':
        return '/seller/kyc';
      case 'order':
        final orderId = data['order_id'] as String?;
        if (orderId != null && orderId.isNotEmpty) {
          return '/profile/orders/$orderId';
        }
        return '/profile/orders';
      case 'seller_order':
        final sellerOrderId = data['order_id'] as String?;
        if (sellerOrderId != null && sellerOrderId.isNotEmpty) {
          return '/seller/orders/$sellerOrderId';
        }
        return '/seller/orders';
      default:
        return null;
    }
  }

  static bool usePushForPath(String path) {
    return path.startsWith('/matching/chat/') ||
        path == '/matching/inbox' ||
        path.startsWith('/social/post/') ||
        path == '/social/notifications' ||
        path.startsWith('/profile/orders/') ||
        path.startsWith('/seller/orders/') ||
        path == '/seller/kyc';
  }

  static void navigate(GoRouter router, Map<String, dynamic> data) {
    final path = routeFromData(data);
    if (path == null) return;
    if (usePushForPath(path)) {
      router.push(path);
    } else {
      router.go(path);
    }
  }
}
