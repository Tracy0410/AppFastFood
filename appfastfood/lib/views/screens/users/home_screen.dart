import 'dart:async';
import 'package:appfastfood/views/screens/users/home_interface/favorite_content.dart';
import 'package:appfastfood/views/screens/users/home_interface/home_content.dart';
import 'package:appfastfood/views/screens/users/faq_screen.dart';
import 'package:appfastfood/views/screens/users/home_interface/order_list_screem.dart';
import 'package:appfastfood/views/screens/users/home_interface/promotion_screen.dart';
import 'package:appfastfood/views/screens/users/notification_side.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../models/products.dart';
import '../../../service/api_service.dart';
import '../../widget/custom_top_bar.dart';
import '../../widget/custom_bottom_bar.dart';
import '../../widget/side_menu.dart';
import 'package:appfastfood/views/widget/filter_modal.dart';
import 'package:appfastfood/utils/notification_helper.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _search = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<List<Product>> _productsFuture;
  Future<List<Product>>? _favoriteFuture;

  List<Product> _homeDisplayProducts = [];
  List<Product> _homeAllProducts = [];
  List<String> _categories = ["All"];
  String _selectedCategory = "All";
  int _currentBottomIndex = 0;

  Widget _currentEndDrawer = const SideMenu();

  Timer? _notificationTimer;

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

    NotificationHelper().init(); 
    NotificationHelper().requestPermission();
    _startBackgroundCheck();
  }

  @override
  void dispose() {
    // Hủy Timer khi thoát màn hình để tránh lỗi
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startBackgroundCheck() {
    // Gọi ngay lần đầu tiên
    _checkOrderUpdates();

    // Lặp lại mỗi 30 giây
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkOrderUpdates();
    });
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

  // HÀM MỞ THÔNG BÁO
  void _openNotificationDrawer() {
    setState(() {
      _currentEndDrawer = const NotificationSide(); // Đổi nội dung thành Thông báo
    });
    // Đợi 1 frame để UI cập nhật rồi mới mở (cho chắc chắn)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
    });
  }

  // HÀM MỞ PROFILE
  void _openProfileDrawer() {
    setState(() {
      _currentEndDrawer = const SideMenu(); // Đổi nội dung thành Menu Profile cũ
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldKey.currentState?.openEndDrawer();
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
        return const OrderListScreen();
      case 4:
        return const FaqScreen();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _currentEndDrawer,

      body: Column(
        children: [
          // TOP BAR
          CustomTopBar(
            isHome: _currentBottomIndex == 0,
            searchController: _search,
            onFilterTap: _showFilterMenu,

            onNotificationTap: _openNotificationDrawer,
            onProfileTap: _openProfileDrawer,
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
            }
          });
        },
      ),
    );
  }

  Future<void> _checkOrderUpdates() async {
    try {
      final data = await _apiService.getNotificationSync();
      if (data.isEmpty || data['orders'] == null) return;

      final prefs = await SharedPreferences.getInstance();
      
      List orders = data['orders'];

      for (var order in orders) {
        int orderId = order['order_id'];
        String newStatus = order['order_status'];
        
        String key = 'order_status_$orderId';
        String? oldStatus = prefs.getString(key);

        // Logic: Nếu chưa từng lưu (đơn mới) HOẶC trạng thái thay đổi
        if (oldStatus != null && oldStatus != newStatus) {
          
          String title = "Đơn hàng #$orderId cập nhật";
          String body = _getStatusMessage(newStatus);
          
          NotificationHelper().showNotification(
            id: orderId,
            title: title,
            body: body,
            type: 'order',
          );
        }

        // Lưu lại trạng thái mới nhất để lần sau so sánh
        await prefs.setString(key, newStatus);
      }
    } catch (e) {
      print("Lỗi kiểm tra thông báo ngầm: $e");
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'PENDING': return 'Đơn hàng đang chờ xác nhận.';
      case 'COOKING': return 'Món ăn đang được chế biến.';
      case 'DELIVERING': return 'Tài xế đang giao hàng đến bạn.';
      case 'COMPLETED': return 'Đơn hàng đã hoàn tất. Chúc ngon miệng!';
      case 'CANCELLED': return 'Đơn hàng đã bị hủy.';
      default: return 'Trạng thái mới: $status';
    }
  }
}
