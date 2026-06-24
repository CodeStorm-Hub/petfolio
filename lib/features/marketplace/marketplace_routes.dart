import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/pf_page_transitions.dart';
import 'data/models/marketplace_order.dart';
import 'data/models/product.dart';
import 'presentation/screens/cart_screen.dart';
import 'presentation/screens/prescription_upload_screen.dart';
import 'presentation/screens/shipment_tracking_screen.dart';
import 'presentation/screens/wishlist_screen.dart';
import 'presentation/screens/customer/buyer_order_detail_screen.dart';
import 'presentation/screens/customer/buyer_order_list_screen.dart';
import 'presentation/screens/customer/shop_storefront_screen.dart';
import 'presentation/screens/order_confirmation_screen.dart';
import 'presentation/screens/product_detail_screen.dart';

List<RouteBase> marketplaceRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/product/:id',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: ProductDetailScreen(
        productId: state.pathParameters['id']!,
        product: state.extra as Product?,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/cart',
    pageBuilder: (context, state) =>
        pfFadeThroughPage(state: state, child: const CartScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/order/:id',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: OrderConfirmationScreen(
        orderId: state.pathParameters['id']!,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/orders/:id',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: BuyerOrderDetailScreen(
        orderId: state.pathParameters['id']!,
        order: state.extra as MarketplaceOrder?,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/profile/orders',
    pageBuilder: (context, state) =>
        pfSharedAxisPage(state: state, child: const BuyerOrderListScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/profile/orders/:id',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: BuyerOrderDetailScreen(
        orderId: state.pathParameters['id']!,
        order: state.extra as MarketplaceOrder?,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/shop/:id',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: ShopStorefrontRoute(
        shopId: state.pathParameters['id']!,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/wishlist',
    pageBuilder: (context, state) =>
        pfSharedAxisPage(state: state, child: const WishlistScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/orders/:id/prescription',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: PrescriptionUploadScreen(
        orderId: state.pathParameters['id']!,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/orders/:id/tracking',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: ShipmentTrackingScreen(
        orderId: state.pathParameters['id']!,
      ),
    ),
  ),
];
