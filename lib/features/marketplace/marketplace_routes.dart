import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/models/marketplace_order.dart';
import 'data/models/product.dart';
import 'presentation/screens/cart_screen.dart';
import 'presentation/screens/customer/buyer_order_detail_screen.dart';
import 'presentation/screens/customer/buyer_order_list_screen.dart';
import 'presentation/screens/customer/shop_storefront_screen.dart';
import 'presentation/screens/order_confirmation_screen.dart';
import 'presentation/screens/product_detail_screen.dart';
import 'presentation/screens/vendor/add_edit_product_screen.dart';
import 'presentation/screens/vendor/edit_shop_screen.dart';
import 'presentation/screens/vendor/manual_kyc_screen.dart';
import 'presentation/screens/vendor/seller_dashboard_screen.dart';
import 'presentation/screens/vendor/shop_setup_screen.dart';
import 'presentation/screens/vendor/stripe_onboarding_screen.dart';
import 'presentation/screens/vendor/vendor_order_detail_screen.dart';
import 'presentation/screens/vendor/vendor_order_queue_screen.dart';
import 'presentation/screens/vendor/vendor_product_list_screen.dart';

List<RouteBase> marketplaceRoutes(GlobalKey<NavigatorState> rootKey) => [
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
    builder: (context, state) => const SellerDashboardScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/setup',
    builder: (context, state) => const ShopSetupScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/onboarding',
    builder: (context, state) {
      final url = state.uri.queryParameters['url'] ?? '';
      return StripeOnboardingScreen(accountLinkUrl: url);
    },
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/edit-shop',
    builder: (context, state) => const EditShopScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/kyc',
    builder: (context, state) => const ManualKycScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products',
    builder: (context, state) => const VendorProductListScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products/add',
    builder: (context, state) => const AddEditProductScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products/:id/edit',
    builder: (context, state) => AddEditProductScreen(
      product: state.extra as Product?,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/orders',
    builder: (context, state) => const VendorOrderQueueScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/orders/:id',
    builder: (context, state) => VendorOrderDetailScreen(
      orderId: state.pathParameters['id']!,
      order: state.extra as MarketplaceOrder?,
    ),
  ),
];
