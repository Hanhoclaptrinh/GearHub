import 'package:mobile/src/features/product_compare/data/models/product_compare_models.dart';

abstract class ProductCompareRepository {
  Future<ProductCompareResultModel> compareProducts(
    List<String> productIds, {
    List<String>? variantIds,
  });
}
