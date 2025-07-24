import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sahara_app/helpers/cart_storage.dart';
import 'package:sahara_app/models/product_category_model.dart';
import 'package:sahara_app/models/staff_list_model.dart';
import 'package:sahara_app/pages/cart_page.dart';
import 'package:sahara_app/pages/cloud_settings.dart';
import 'package:sahara_app/pages/pos_settings_form.dart';
import 'package:sahara_app/pages/product_list_page.dart';
import 'package:sahara_app/pages/products_page.dart';
import 'package:sahara_app/pages/settings_page.dart';
import 'package:sahara_app/pages/sync_items_page.dart';
import 'package:sahara_app/pages/users_page.dart';
import 'package:sahara_app/utils/colors_universal.dart';
import 'package:sahara_app/widgets/reusable_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});
  final StaffListModel user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hint: Text('Search Product Categories', style: TextStyle(color: Colors.grey[400])),
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
              itemCount: _filteredCategories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .9),
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Card(
                    color: Colors.brown[50],
                    child: InkWell(
                      radius: 3,
                      //splashColor: ColorsUniversal.fillWids,
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _activeCategoryPage = ProductListPage(
                            categoryName: category.productCategoryName,
                            products: category.products,
                            onBack: () {
                              setState(() {
                                _activeCategoryPage = null;
                              });
                            },
                          );
                        });
                      },
                      child: SizedBox(
                        width: 120,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/pump cropped.png',
                                fit: BoxFit.fitWidth,
                                width: 50,
                                color: ColorsUniversal.fillWids,
                              ),
                              SizedBox(height: 12),
                              Text('Category Name:', style: TextStyle(fontSize: 15, color: Colors.black54)),
                              Text(
                                category.productCategoryName,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final CartStorage cartStorage = CartStorage();

  ProductListPage? _selectedProductListPage;
  ProductListPage? _activeCategoryPage;

  final TextEditingController _searchController = TextEditingController();
  List<ProductCategoryModel> _allcategories = [];
  List<ProductCategoryModel> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesFromHive();
    _searchController.addListener(_filterCategories);
    cartStorage.addListener((){
      if (mounted) {
        setState(() {
          
        });
      }
    });
  }

  void _loadCategoriesFromHive() {
    final box = Hive.box('products');
    final data = box.get('productItems') as List?;

    if (data != null) {
      final loadedCategories = data.map((e) => ProductCategoryModel.fromJson(Map<String, dynamic>.from(e))).toList();

      setState(() {
        _allcategories = loadedCategories;
        _filteredCategories = loadedCategories;
      });
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredCategories = _allcategories.where((cat) {
        return cat.productCategoryName.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _selectedIndex = 0;

  List<Widget> get _screens => [
    _activeCategoryPage != null ? _activeCategoryPage! : _buildHomeScreen(), // home layout
    ProductsPage(),
    SettingsPage(user: widget.user,),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsUniversal.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.user.staffName, style: TextStyle(color: Colors.white70)),
        centerTitle: true,
        backgroundColor: ColorsUniversal.appBarColor,
        iconTheme: IconThemeData(color: Colors.white70),
        actions: [
          // ADVANCED DROPDOWN
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: ColorsUniversal.background,
            icon: Icon(Icons.build_circle_outlined, color: Colors.white70, size: 28),
            onSelected: (value) {
              if (value == 'sync') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SyncItemsPage()));
              } else if (value == 'pos') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: ColorsUniversal.background,
                      appBar: myAppBar('POS Settings'),
                      body: const Padding(padding: EdgeInsets.all(12), child: PosSettingsForm(showSyncButton: false)),
                    ),
                  ),
                );
              } else if (value == 'automation') {
                // Add automation settings page nav
              } else if (value == 'cloud') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CloudSettings()));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'sync', child: Text('Sync Items')),
              PopupMenuItem(value: 'pos', child: Text('POS Settings')),
              PopupMenuItem(value: 'automation', child: Text('Automation Settings')),
              PopupMenuItem(value: 'cloud', child: Text('Cloud Settings')),
            ],
          ),

          // LOGOUT ICON BUTTON
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: ColorsUniversal.background,
                    title: Text('LOG OUT'),
                    content: Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: Colors.brown[800], fontSize: 17)),
                      ),
                      TextButton(
                        child: Text('OK', style: TextStyle(color: Colors.brown[800], fontSize: 17)),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => UsersPage()));
                        },
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.logout, color: Colors.white70),
          ),
        ],
      ),

      body: _selectedProductListPage != null ? _selectedProductListPage! : _screens[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: ColorsUniversal.fillWids,
        activeColor: ColorsUniversal.buttonsColor,
        color: Colors.white70,
        style: TabStyle.react, // or `fixed`, `flip`, etc.
        curveSize: 70,
        items: const [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.list_alt, title: 'Products'),
          TabItem(icon: Icons.settings, title: 'Settings'),
        ],
        initialActiveIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;

            if (index == 0) {
              _activeCategoryPage = null;
            }
          });
        },
      ),
      // Floating Action Button positioned above bottom nav
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  CartPage(user:  widget.user,)),
          ).then((_) => setState(() {})); // Refresh when coming back
        },
        backgroundColor: ColorsUniversal.buttonsColor,
        child: Badge(
          isLabelVisible: cartStorage.cartItems.isNotEmpty,
          label: Text('${cartStorage.cartItems.length}'),
          offset: Offset(9, -9),
          backgroundColor: ColorsUniversal.appBarColor,
          child: const Icon(Icons.shopping_cart, color: Colors.white70),
        ),
      ),

      // Position the FAB properly
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
