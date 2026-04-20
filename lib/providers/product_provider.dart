import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:mf_tracker/database/database_helper.dart';
import 'package:mf_tracker/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  ProductModel? _currentProduct;
  bool _isLoading = false;

  ProductModel? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;

  Future<void> loadAndSyncData() async {
    _isLoading = true;
    notifyListeners();

    // 1. READ LOCAL: Ask the helper for cached data
    final cachedData = await DatabaseHelper.instance.getCachedProduct();
    if (cachedData != null) {
      _currentProduct = ProductModel.fromJson(cachedData);
      notifyListeners();
    }

    try {
      // 2. FETCH REMOTE
      final url = Uri.parse('https://dummyjson.com/products/1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final freshProduct = ProductModel.fromJson(decodedData);

        // 3. CACHE IT: Hand the mapped data to our helper to save
        await DatabaseHelper.instance.cacheProduct(freshProduct.toMap());

        // 4. UPDATE UI
        _currentProduct = freshProduct;
      }
    } catch (e) {
      print('Network fetch failed with error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
