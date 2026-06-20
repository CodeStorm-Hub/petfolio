import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import 'presentation/screens/marketplace_categories_screen.dart';
import 'presentation/screens/product_detail_screen.dart';
import 'presentation/screens/vendor_web_redirect_screen.dart';

List<RouteBase> marketplaceRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/categories',
    builder: (_, _) => const MarketplaceCategoriesScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/product/:id',
    builder: (context, state) => ProductDetailScreen(
      productId: state.pathParameters['id']!,
      product: state.extra as Product?,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/cart',
    builder: (context, state) => const CartScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/order/:id',
    builder: (context, state) => OrderConfirmationScreen(
      orderId: state.pathParameters['id']!,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/orders/:id',
    builder: (context, state) => BuyerOrderDetailScreen(
      orderId: state.pathParameters['id']!,
      order: state.extra as MarketplaceOrder?,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/profile/orders',
    builder: (context, state) => const BuyerOrderListScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/profile/orders/:id',
    builder: (context, state) => BuyerOrderDetailScreen(
      orderId: state.pathParameters['id']!,
      order: state.extra as MarketplaceOrder?,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/shop/:id',
    builder: (context, state) => ShopStorefrontRoute(
      shopId: state.pathParameters['id']!,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/setup',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/edit-shop',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/kyc',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products/add',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products/:id/edit',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/orders',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/orders/:id',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/earnings',
    builder: (context, state) => const VendorWebRedirectScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/wishlist',
    builder: (_, _) => const WishlistScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/orders/:id/prescription',
    builder: (context, state) => PrescriptionUploadScreen(
      orderId: state.pathParameters['id']!,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/orders/:id/tracking',
    builder: (context, state) => ShipmentTrackingScreen(
      orderId: state.pathParameters['id']!,
    ),
  ),
];
