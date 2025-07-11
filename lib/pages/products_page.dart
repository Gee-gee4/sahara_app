// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/product_category_model.dart';
import 'package:sahara_app/models/product_model.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<ProductModel> _allProducts = [];

  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  void _loadAllProducts() {
    final box = Hive.box('products');
    final data = box.get('productItems') as List?;

    if (data != null) {
      final categories = data
          .map((e) => ProductCategoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final all = <ProductModel>[];
      for (var category in categories) {
        all.addAll(category.products);
      }

      setState(() {
        _allProducts = all;
        _filteredProducts = all;
      });
    }
  }

  void _filterProducts(String query) {
    final filtered = _allProducts.where((product) {
      return product.productName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      // appBar: AppBar(
      //   title: const Text('All Products'),
      //   backgroundColor: ColorsUniversal.appBarColor,
      //   foregroundColor: Colors.white,
      // ),
      body: _allProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _filterProducts,
                    decoration: InputDecoration(
                      hint: Text(
                        'Search Products',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      prefixIcon: Icon(Icons.search),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.brown[300]!),
                      ),
                    ),
                    cursorColor: Colors.brown[300],
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      itemCount: _filteredProducts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: .9,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final variation = product.productVariations.isNotEmpty
                            ? product.productVariations[0]
                            : null;

                        return Card(
                          color: Colors.brown[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_basket,
                                  size: 36,
                                  color: Colors.brown[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  product.productName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (variation != null)
                                  Text(
                                    'Ksh ${variation.productVariationPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.brown[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                SizedBox(height: 6),
                                myButton(context, () {
                                  if (variation != null) {
                                    CartStorage.addToCart(
                                      product.productName,
                                      variation.productVariationPrice,
                                      variation.productVariationId.toString(),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.productName} added to cart',
                                        ),
                                      ),
                                    );
                                  }
                                }, 'ADD TO CART'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
