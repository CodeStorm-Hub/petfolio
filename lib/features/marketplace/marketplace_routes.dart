import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/transitions.dart';
import 'data/models/marketplace_order.dart';
import 'data/models/product.dart';
import 'presentation/screens/cart_screen.dart';
import 'presentation/screens/shop_intro_screen.dart';
import 'presentation/screens/customer/buyer_order_detail_screen.dart';
import 'presentation/screens/customer/buyer_order_list_screen.dart';
import 'presentation/screens/customer/shop_storefront_screen.dart';
import 'presentation/screens/order_confirmation_screen.dart';
import 'presentation/screens/marketplace_categories_screen.dart';
import 'presentation/screens/product_detail_screen.dart';
import 'presentation/screens/vendor/add_edit_product_screen.dart';
import 'presentation/screens/vendor/edit_shop_screen.dart';
import 'presentation/screens/vendor/manual_kyc_screen.dart';
import 'presentation/screens/vendor/seller_dashboard_screen.dart';
import 'presentation/screens/vendor/shop_setup_screen.dart';
import 'presentation/screens/vendor/stripe_onboarding_screen.dart';
import 'presentation/screens/vendor/vendor_order_detail_screen.dart';
import 'presentation/screens/vendor/vendor_earnings_screen.dart';
import 'presentation/screens/vendor/vendor_order_queue_screen.dart';
import 'presentation/screens/vendor/vendor_product_list_screen.dart';

List<RouteBase> marketplaceRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/intro',
    pageBuilder: (_, state) => pushPage(key: state.pageKey, child: const ShopIntroScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/categories',
    pageBuilder: (_, state) => pushPage(key: state.pageKey, child: const MarketplaceCategoriesScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/product/:id',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: ProductDetailScreen(
        productId: state.pathParameters['id']!,
        product: state.extra as Product?,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/cart',
    pageBuilder: (context, state) => modalPage(key: state.pageKey, child: const CartScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/order/:id',
    pageBuilder: (context, state) => modalPage(
      key: state.pageKey,
      child: OrderConfirmationScreen(orderId: state.pathParameters['id']!),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/marketplace/orders/:id',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: BuyerOrderDetailScreen(
        orderId: state.pathParameters['id']!,
        order: state.extra as MarketplaceOrder?,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/profile/orders',
    pageBuilder: (context, state) => pushPage(key: state.pageKey, child: const BuyerOrderListScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/profile/orders/:id',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: BuyerOrderDetailScreen(
        orderId: state.pathParameters['id']!,
        order: state.extra as MarketplaceOrder?,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/shop/:id',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: ShopStorefrontRoute(shopId: state.pathParameters['id']!),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller',
    pageBuilder: (context, state) => pushPage(key: state.pageKey, child: const SellerDashboardScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/setup',
    pageBuilder: (context, state) => modalPage(key: state.pageKey, child: const ShopSetupScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/onboarding',
    pageBuilder: (context, state) {
      final url = state.uri.queryParameters['url'] ?? '';
      return pushPage(key: state.pageKey, child: StripeOnboardingScreen(accountLinkUrl: url));
    },
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/edit-shop',
    pageBuilder: (context, state) => modalPage(key: state.pageKey, child: const EditShopScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/kyc',
    pageBuilder: (context, state) => modalPage(key: state.pageKey, child: const ManualKycScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products',
    pageBuilder: (context, state) => pushPage(key: state.pageKey, child: const VendorProductListScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products/add',
    pageBuilder: (context, state) => modalPage(key: state.pageKey, child: const AddEditProductScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/products/:id/edit',
    pageBuilder: (context, state) => modalPage(
      key: state.pageKey,
      child: AddEditProductScreen(product: state.extra as Product?),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/orders',
    pageBuilder: (context, state) => pushPage(key: state.pageKey, child: const VendorOrderQueueScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/orders/:id',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: VendorOrderDetailScreen(
        orderId: state.pathParameters['id']!,
        order: state.extra as MarketplaceOrder?,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/seller/earnings',
    pageBuilder: (context, state) => pushPage(key: state.pageKey, child: const VendorEarningsScreen()),
  ),
];
