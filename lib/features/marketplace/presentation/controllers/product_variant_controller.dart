import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/product_variant.dart';
import '../../data/repositories/product_repository.dart';

part 'product_variant_controller.g.dart';

@riverpod
Future<List<ProductVariant>> productVariants(Ref ref, String productId) =>
    ref.read(productRepositoryProvider).fetchVariants(productId);
