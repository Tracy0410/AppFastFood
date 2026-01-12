import 'package:appfastfood/models/order.dart';
import 'package:appfastfood/views/screens/users/home_interface/favorite_content.dart';
import 'package:appfastfood/views/screens/users/home_interface/home_content.dart';
import 'package:appfastfood/views/screens/users/faq_screen.dart';
import 'package:appfastfood/views/screens/users/home_interface/promotion_screen.dart';
import 'package:appfastfood/views/screens/users/order_list_screem.dart';
import 'package:flutter/material.dart';
import '../../../models/products.dart';
import '../../../service/api_service.dart';
import '../../widget/custom_top_bar.dart';
import '../../widget/custom_bottom_bar.dart';
import '../../widget/side_menu.dart';
import 'package:appfastfood/views/widget/filter_modal.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _search = TextEditingController();

  late Future<List<Product>> _productsFuture;
  Future<List<Product>>? _favoriteFuture;
  Future<List<OrderModel>>? _OrderList;

  List<Product> _homeDisplayProducts = [];
  List<Product> _homeAllProducts = [];
  List<String> _categories = ["All"];
  String _selectedCategory = "All";
  int _currentBottomIndex = 0;

  List<CategoryItem> _filterCategories =
      []; // <--- MỚI THÊM (Biến chứa danh mục cho bộ lọc)

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadHomeData();

    // Lắng nghe ô tìm kiếm
    _search.addListener(() {
      if (_currentBottomIndex == 0) {
        _filterProducts(_search.text);
      }
    });

    _refreshFavData();
  }

  // Hàm load dữ liệu và cập nhật State cho Home
  Future<List<Product>> _loadHomeData() async {
    final products = await _apiService.getAllProducts();
    _search.clear();

    if (mounted && products.isNotEmpty) {
      setState(() {
        _homeAllProducts = products;
        _homeDisplayProducts = products;

        final categories = products.map((p) => p.categoryName).toSet().toList();
        _categories = ["All", ...categories];
        _selectedCategory = "All";

        // --- MỚI THÊM (Lấy dữ liệu cho bảng lọc) ---
        final uniqueCats = <int, String>{};
        for (var p in products) {
          uniqueCats[p.categoryId] = p.categoryName;
        }
        _filterCategories = uniqueCats.entries
            .map((e) => CategoryItem(id: e.key.toString(), name: e.value))
            .toList();
        // ------------------------------------------
      });
    }
    return products;
  }

  // --- MỚI THÊM (Hàm hiển thị menu lọc) ---
  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FilterModal(
            categories: _filterCategories,
            // Callback bây giờ nhận về maxPrice (double) thay vì RangeValues
            onApply: (catId, rating, maxPrice) {
              _applyAdvancedFilter(catId, rating, maxPrice);
            },
          ),
        );
      },
    );
  }
  // ----------------------------------------

  // --- MỚI THÊM (Hàm gọi API lọc) ---
  Future<void> _applyAdvancedFilter(
    String categoryId,
    int rating,
    double maxPrice,
  ) async {
    setState(() {});
    try {
      final result = await _apiService.filterProducts(
        categoryId: categoryId,
        rating: rating,
        minPrice: 0, // <--- LUÔN SET MIN LÀ 0
        maxPrice: maxPrice, // <--- SET MAX THEO THANH KÉO
      );
      setState(() {
        _homeDisplayProducts = result;
        _productsFuture = Future.value(result);
      });
    } catch (e) {
      print("Lỗi Filter: $e");
    }
  }
  // ----------------------------------

  // Hàm refresh cho Home
  Future<List<Product>> _refreshHome() async {
    setState(() {
      _productsFuture = _loadHomeData();
    });
    return _productsFuture;
  }

  // Hàm refresh cho Favorite
  Future<List<Product>> _refreshFavData() async {
    final future = _apiService.getFavoriteList();
    setState(() {
      _favoriteFuture = future;
    });
    return future;
  }

  Future<List<OrderModel>> _refeshOrderData() async {
    final data = _apiService.getOrderYourUserId();
    setState(() {
      _OrderList = data;
    });
    return data;
  }

  // Hàm lọc sản phẩm theo search text
  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _homeDisplayProducts = _homeAllProducts);
    } else {
      setState(() {
        _homeDisplayProducts = _homeAllProducts
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // Hàm load dữ liệu cho Favorite
  Future<List<Product>> _loadFavData() async {
    return await _apiService.getFavoriteList();
  }

  Future<List<OrderModel>> _loadOrderData() async {
    return await _apiService.getOrderYourUserId();
  }

  // Hàm lọc theo danh mục
  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == "All") {
        _homeDisplayProducts = _homeAllProducts;
      } else {
        _homeDisplayProducts = _homeAllProducts
            .where((p) => p.categoryName == category)
            .toList();
      }
    });
  }

  Widget _getBodyContent() {
    switch (_currentBottomIndex) {
      case 0:
        return HomeContent(
          categories: _categories,
          selectedCategory: _selectedCategory,
          displayProducts: _homeDisplayProducts,
          productsFuture: _productsFuture,
          onCategorySelected: _filterByCategory,
          onRefresh: _refreshHome,
        );
      case 1:
        return const PromotionScreen();
      case 2:
        return FavoriteContent(
          favoriteProducts: [],
          productsFuture: _favoriteFuture,
          onRefresh: _refreshFavData,
        );
      case 3:
        return OrderListScreen(onRefresh: _refeshOrderData);
      case 4:
        return const FaqScreen();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const SideMenu(),
      body: Column(
        children: [
          // TOP BAR
          CustomTopBar(
            isHome:
                _currentBottomIndex ==
                0, // Chỉ hiện lời chào "Good Morning" ở trang Home
            searchController: _search,
            // --- MỚI THÊM (Gắn sự kiện bấm nút lọc) ---
            onFilterTap: _showFilterMenu,
            // ------------------------------------------
          ),

          //NỘI DUNG THAY ĐỔI
          Expanded(child: _getBodyContent()),
        ],
      ),

      // BOTTOM BAR
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: _currentBottomIndex,
        onItemTapped: (index) {
          // Các nút khác thì hoạt động như cũ
          setState(() {
            _currentBottomIndex = index;
            if (index == 2) {
              _loadFavData();
            } else if (index == 3) {
              _loadOrderData();
            }
          });
        },
      ),
    );
  }
}
