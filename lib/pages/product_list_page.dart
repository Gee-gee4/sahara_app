import 'package:flutter/material.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/product_model.dart';
import 'package:sahara_app/utils/color_hex.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class ProductListPage extends StatefulWidget {
  final String categoryName;
  final List<ProductModel> products;
  final VoidCallback onBack;

  const ProductListPage({
    super.key,
    required this.categoryName,
    required this.products,
    required this.onBack,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  void _filterProducts(String query) {
    final results = widget.products.where((product) {
      return product.productName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredProducts = results;
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
      body: Padding(
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
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
                            Icons.shopping_cart,
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
                                  //behavior: SnackBarBehavior.floating,
                                  duration: const Duration(milliseconds: 500),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: hexToColor('8f9c68'),
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
