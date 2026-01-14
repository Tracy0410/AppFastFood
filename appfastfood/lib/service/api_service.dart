import 'dart:io';
import 'package:appfastfood/models/address.dart';
import 'package:appfastfood/models/cartItem.dart';
import 'package:appfastfood/models/Order.dart';
import 'package:appfastfood/models/user.dart';
import 'package:appfastfood/models/promotion.dart';
import 'package:appfastfood/models/reviewModel.dart';
import 'package:appfastfood/utils/storage_helper.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import '../models/products.dart';
import '../models/checkout.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://192.168.68.37:8001'; //máy thật
  static const String BaseUrl = 'http://10.0.2.2:8001'; // máy ảo

  static final String urlEdit = BaseUrl; //chỉnh url trên đây thôi

  // Đăng nhập
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse('$urlEdit/api/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          jsonResponse['success'] == true &&
          jsonResponse['token'] != null) {
        await StorageHelper.saveToken(jsonResponse['token']);
        await StorageHelper.saveUserId(jsonResponse['user']['user_id']);

        return jsonResponse;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  // Đăng ký tài khoản
  Future<Map<String, dynamic>> register(
    String username,
    String password,
    String fullname,
    String email,
    String phone,
  ) async {
    try {
      final url = Uri.parse('$urlEdit/api/register');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'fullname': fullname,
          'email': email,
          'phone': phone,
        }),
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          jsonResponse['success'] == true) {
        return jsonResponse;
      } else {
        throw Exception(
          jsonResponse['message'] ?? 'Đăng ký thất bại (Lỗi không xác định)',
        );
      }
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  // Xóa tài khoản
  Future<bool> deleteAccount(int userId) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return false;

      final uri = Uri.parse('$urlEdit/api/delete/$userId');

      print("Dang goi API xoa: $uri"); // In ra để check link

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        "Status Code: ${response.statusCode}",
      ); // Quan trọng: Xem mã lỗi (200, 404, 500?)
      print(
        "Response Body: ${response.body}",
      ); // Quan trọng: Xem server báo lỗi gì

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print("Lỗi Exception Flutter: $e");
      return false;
    }
  }

  // Lấy thông tin profile
  Future<User?> getProfile() async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return null;

      final url = Uri.parse('$urlEdit/api/profile');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          User user = User.fromJson(data['user']);
          // await StorageHelper.saveImage(user.image);
          // await StorageHelper.saveFullname(user.fullname);
          return user;
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return null;
  }

  // Cập nhật thông tin profile
  Future<bool> updateProfile({
    required String fullname,
    required String email,
    required String phone,
    required String birthday,
    File? imageFile,
  }) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return false;

      var uri = Uri.parse('$urlEdit/api/profile/update');
      var request = http.MultipartRequest('POST', uri);

      // Header Authorization
      request.headers['Authorization'] = 'Bearer $token';
      // Gửi các trường text (Text Fields)
      request.fields['fullname'] = fullname;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['birthday'] = birthday;

      if (imageFile != null) {
        var pic = await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(pic);
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Cập nhật lại StorageHelper nếu server trả về user mới
          if (data['user'] != null) {
            User updatedUser = User.fromJson(data['user']);
            await StorageHelper.saveImage(updatedUser.image);
            await StorageHelper.saveFullname(updatedUser.fullname);
          }
          return true;
        }
      } else {
        print("Update Failed: ${response.body}");
      }
      return false;
    } catch (e) {
      print('Lỗi updateProfile: $e');
      return false;
    }
  }

  // Gửi OTP
  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final url = Uri.parse('$urlEdit/api/send-otp');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gửi OTP thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi gửi OTP: $e');
    }
  }

  // Đặt lại mật khẩu
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final url = Uri.parse('$urlEdit/api/reset-password');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Đặt lại mật khẩu thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi đặt lại mật khẩu: $e');
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPass,
    String newPass,
    String confirmPass
  ) async {
    try{
      final String? token = await StorageHelper.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final url = Uri.parse('$urlEdit/api/profile/change-password');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPass,
          'newPassword': newPass,
          'confirmPassword': confirmPass,
        })
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': data['message'] ?? 'Đổi mật khẩu thành công'
        };
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Lỗi không xác định'
        };
      }
    }catch(e){
      return {'success': false, 'message': 'Lỗi kết nối server'};
    }
  }

  // Lấy tất cả sản phẩm
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$urlEdit/api/products'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((item) => Product.fromJson(item)).toList();
        } else {
          throw Exception("API Error: ${jsonResponse['message']}");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      return []; // Trả về rỗng để UI không bị crash
    }
  }

  // Lấy chi tiết sản phẩm theo ID
  Future<Product?> getProductById(int id) async {
    try {
      final res = await http.get(Uri.parse('$urlEdit/api/products/$id'));

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonRes = jsonDecode(res.body);

        if (jsonRes['success']) {
          Map<String, dynamic> data = jsonRes['data'];
          return Product.fromJson(data);
        }
      }
    } catch (e) {
      throw "Error not found product $e";
    }
    return null;
  }

  // Favorite APIs
  Future<bool> addFavorites(int productId) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) {
        return false;
      }
      final url = Uri.parse('$urlEdit/api/favorites/add');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_id': productId}),
      );
      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Lỗi addFavorite $e");
      return false;
    }
  }

  // Kiểm tra favorite
  Future<bool> checkFav(int productId) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return false;
      final res = await http.get(
        Uri.parse('$urlEdit/api/favorites/check?product_id=$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        return jsonRes['isFavorited'] == true;
      }
      return false;
    } catch (e) {
      print('Lỗi check fav $e');
      return false;
    }
  }

  // Xóa favorite
  Future<bool> removeFavorite(int productId) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return false;

      final res = await http.post(
        Uri.parse('$urlEdit/api/favorites/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'product_id': productId}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Lỗi removeFavoreites $e');
      return false;
    }
  }

  // Lấy danh sách sản phẩm yêu thích
  Future<List<Product>> getFavoriteList() async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return [];

      final res = await http.get(
        Uri.parse('$urlEdit/api/favorites/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          List<dynamic> data = jsonRes['data'];
          return data.map((item) => Product.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Lỗi getFavoriteList: $e');
      return [];
    }
  }

  Future<List<CartItem>> getCartList() async {
    final token = await StorageHelper.getToken();
    final res = await http.get(
      Uri.parse('$urlEdit/api/carts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final jRes = jsonDecode(res.body);
      if (jRes['success']) {
        return (jRes['data'] as List)
            .map((items) => CartItem.fromJson(items))
            .toList();
      }
    }
    return [];
  }

  Future<bool> addToCart(int productId, int quantity, String note) async {
    final token = await StorageHelper.getToken();
    final res = await http.post(
      Uri.parse('$urlEdit/api/carts/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
        'note': note,
      }),
    );
    return res.statusCode == 200;
  }

  Future<bool> updateCart(int cartId, int quantity, String note) async {
    final token = await StorageHelper.getToken();
    final res = await http.put(
      Uri.parse('$urlEdit/api/carts/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'cart_id': cartId, 'quantity': quantity, 'note': note}),
    );
    return res.statusCode == 200;
  }

  Future<bool> removeCart(int cartId) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return false;

      final res = await http.delete(
        Uri.parse('$urlEdit/api/carts/delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'cart_id': cartId}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Lỗi removeCart $e');
      return false;
    }
  }

  //Lấy mã Khuyến Mãi
  Future<List<Promotion>> getPromotions() async {
    final url = Uri.parse('$urlEdit/api/promotions');

    try {
      print('GET $url');
      final response = await http.get(url);
      print('Promotions response status: ${response.statusCode}');
      print('Promotions response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List<dynamic> dataList;
        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          dataList = decoded['data'];
        } else if (decoded is Map &&
            decoded['success'] == true &&
            decoded['data'] == null) {
          // Unexpected but handle gracefully
          return [];
        } else {
          print('Unexpected promotions JSON shape: ${decoded.runtimeType}');
          return [];
        }

        return dataList.map((json) => Promotion.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print("Lỗi getPromotions: $e");
      return [];
    }
  }

  Future<int?> getDefaultAddessId() async {
    try {
      final token = await StorageHelper.getToken();
      final res = await http.get(
        Uri.parse('$urlEdit/api/address/check'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> address = data['data'];
        if (address.isNotEmpty) {
          return address[0]['address_id'];
        }
      }
      return null;
    } catch (e) {
      print('Lỗi không tìm thấy địa chỉ');
      return null;
    }
  }

  Future<bool> addAddress(
    String name,
    String street,
    String district,
    String city,
  ) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return false;

      final url = Uri.parse('$urlEdit/api/addresses/add');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'street': street,
          'district': district,
          'city': city,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Có thể in ra lỗi từ server để debug
        final body = jsonDecode(response.body);
        print("Lỗi thêm địa chỉ: ${body['message']}");
        return false;
      }
    } catch (e) {
      print("Lỗi server addAddress: $e");
      return false;
    }
  }

  // Đặt địa chỉ mặc định
  Future<bool> setDefaultAddress(int addressId) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return false;

      final url = Uri.parse('$urlEdit/api/addresses/setup');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'address_id': addressId}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Lỗi set default address: $e");
      return false;
    }
  }

  // Xóa địa chỉ
  Future<bool> deleteAddress(int addressId) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return false;

      final url = Uri.parse('$urlEdit/api/addresses/delete');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'address_id': addressId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final body = jsonDecode(response.body);
        print("Lỗi xóa địa chỉ: ${body['message']}");
        return false;
      }
    } catch (e) {
      print("Lỗi delete address: $e");
      return false;
    }
  }

  Future<CheckoutPreviewRes?> previewOrder({
    required List<Map<String, dynamic>>
    items, // Gửi lên: [{ "productId": 1, "quantity": 2 }]
    int? promotionId,
    int? shippingAddressId,
  }) async {
    try {
      final token = await StorageHelper.getToken();
      final url = Uri.parse('$urlEdit/api/orders/preview');

      final body = {
        "items": items,
        "promotionId": promotionId,
        "shippingAddressId": shippingAddressId,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          // Map dữ liệu từ 'data' vào Model
          return CheckoutPreviewRes.fromJson(jsonResponse['data']);
        }
      } else {
        print("Lỗi Preview: ${response.body}");
      }
    } catch (e) {
      print("Exception Preview: $e");
    }
    return null;
  }

  Future<List<Address>> getAddress() async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return [];

      final res = await http.get(
        Uri.parse('$urlEdit/api/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          List<dynamic> data = jsonRes['data'];
          return data.map((item) => Address.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. API Tạo đơn hàng (Create Order Transaction)
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required int shippingAddressId,
    int? promotionId,
    String? note = '',
    String paymentMethod = 'COD',
    bool isBuyFromCart = false,
  }) async {
    try {
      final token = await StorageHelper.getToken();
      final url = Uri.parse(
        '$urlEdit/api/orders/create',
      ); // Route backend phải khớp cái này

      final body = {
        "items": items,
        "shippingAddressId": shippingAddressId,
        "promotionId": promotionId,
        "note": note,
        "paymentMethod": paymentMethod,
        "isBuyFromCart": isBuyFromCart,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse; // Trả về cả cục để Screen check success true/false
    } catch (e) {
      throw Exception("Lỗi tạo đơn hàng: $e");
    }
  }

  // --- MỚI THÊM: Hàm lọc sản phẩm nâng cao ---
  Future<List<Product>> filterProducts({
    required String categoryId,
    required int rating,
    required double minPrice,
    required double maxPrice,
  }) async {
    try {
      // 1. Tạo Query String để gửi dữ liệu lên server
      // Lưu ý: Endpoint này phải khớp với Backend của bạn (ví dụ: /api/products/filter)
      // Nếu categoryId là "All", backend cần xử lý để bỏ qua lọc theo danh mục
      final queryParams = {
        'categoryId': categoryId, // Sửa category_id -> categoryId
        'rating': rating.toString(), // Giữ nguyên
        'minPrice': minPrice.toString(), // Sửa min_price -> minPrice
        'maxPrice': maxPrice.toString(), // Sửa max_price -> maxPrice
      };

      // 2. Tạo URI
      // Cách 1: Ghép chuỗi thủ công (giống phong cách code cũ của bạn)
      // final url = Uri.parse('$urlEdit/api/products/filter?category_id=$categoryId&rating=$rating&min_price=$minPrice&max_price=$maxPrice');

      // Cách 2: Dùng Uri.http/https hoặc replace queryParameters (Chuẩn hơn)
      final uri = Uri.parse(
        '$urlEdit/api/products/filter',
      ).replace(queryParameters: queryParams);

      print("Calling Filter API: $uri"); // Log để kiểm tra link

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
        // Nếu API yêu cầu token thì uncomment dòng dưới:
        // headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${await StorageHelper.getToken()}'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          List<dynamic> data = jsonResponse['data'];
          return data.map((item) => Product.fromJson(item)).toList();
        } else {
          print("Filter API trả về false: ${jsonResponse['message']}");
        }
      } else {
        print("Lỗi Server Filter: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi kết nối filterProducts: $e");
    }
    return []; // Trả về danh sách rỗng nếu lỗi
  }

   // Đăng nhập Admin (Dùng chung login của bạn, giữ nguyên logic lưu role)
  Future<Map<String, dynamic>> loginAdmin(String username, String password) async {
    return login(username, password); // Gọi lại hàm login ở trên
  }

  // 1. Lấy danh sách đơn hàng Admin (ĐÃ SỬA LỖI FILTER)
  Future<List<dynamic>> getAdminOrders(String status) async {
    try {
      final token = await StorageHelper.getToken();
      
      // Xử lý tham số query string chuẩn xác
      // Nếu status có dữ liệu => thêm ?status=...
      // Nếu status rỗng => không thêm gì (để backend tự hiểu là lấy all hoặc xử lý mặc định)
      String queryString = "";
      if (status.isNotEmpty && status != 'ALL') {
         queryString = "?status=$status";
      }

      // URL ví dụ: http://.../api/admin/orders?status=PENDING
      final url = Uri.parse('$urlEdit/api/orders$queryString');

      print("👉 [ADMIN API] Calling: $url"); // Log để debug xem URL đúng chưa

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']; // Trả về List đơn hàng
        }
      } else {
        print("❌ Lỗi Server: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi getAdminOrders: $e");
    }
    return [];
  }

  // 2. Cập nhật trạng thái đơn hàng (Duyệt/Hủy/Giao)
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
  try {
    final token = await StorageHelper.getToken();
    final url = Uri.parse('$urlEdit/api/orders/update-status');

    print("👉 [ADMIN API] Updating Order #$orderId to $newStatus");

    // SỬA LẠI: thay http.put bằng http.post
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'order_id': orderId,
        'status': newStatus,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
  } catch (e) {
    print("❌ Lỗi updateOrderStatus: $e");
  }
  return false;
}

  // 3. Lấy thống kê Dashboard (Doanh thu, Số đơn)
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await StorageHelper.getToken();
      // Sửa URL cho đúng chuẩn Node.js (bỏ .php)
      final url = Uri.parse('$urlEdit/api/stats'); 

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']; // Mong đợi: { revenue: 100000, total_orders: 5, ... }
        }
      }
    } catch (e) {
      print("❌ Lỗi getDashboardStats: $e");
    }
    return {'revenue': 0, 'total_orders': 0};
  }

  // 4. (MỚI) Xóa sản phẩm (Dành cho Admin quản lý món ăn)
  Future<bool> deleteProduct(int productId) async {
    try {
      final token = await StorageHelper.getToken();
      final url = Uri.parse('$urlEdit/api/products/$productId'); // API xóa theo ID

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print("❌ Lỗi deleteProduct: $e");
    }
    return false;
  }
  double safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Xử lý nếu có dấu chấm/thập phân
      String cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  Future<List<OrderModel>> getOrderYourUserId() async {
    try {
      final token = await StorageHelper.getToken();
      final res = await http.get(
        Uri.parse('$urlEdit/api/order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) {
        final jsnres = jsonDecode(res.body);
        if (jsnres is Map && jsnres['success'] == true) {
          final List<dynamic> data = jsnres['data'];
          return data.map((e) => OrderModel.fromJson(e)).toList();
        } else if (jsnres is List) {
          return jsnres.map((e) => OrderModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Lỗi getMyOrders: $e");
      return [];
    }
  }

  Future<OrderModel?> getOrderDetail(int orderId) async {
    try {
      final token = await StorageHelper.getToken();
      final url = Uri.parse('$urlEdit/api/order/$orderId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(response.body);
        if (jsonRes['success'] == true) {
          return OrderModel.fromJson(jsonRes['data']);
        }
      }
      return null;
    } catch (e) {
      print("Lỗi getOrderDetail: $e");
      return null;
    }
  }

  // Hàm thanh toán nhanh (Fake Pay)
  Future<bool> repayOrder(int orderId) async {
    try {
      final token = await StorageHelper.getToken();
      final url = Uri.parse(
        '$urlEdit/api/order/repay',
      ); // Đường dẫn đến hàm retryPayment ở trên

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'orderId': orderId}),
      );

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(response.body);
        return jsonRes['success'] == true; // Trả về true nếu server bảo ok
      }
    } catch (e) {
      print("Lỗi thanh toán nhanh: $e");
    }
    return false;
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      final token = await StorageHelper.getToken();
      final url = Uri.parse('$urlEdit/api/order/cancel');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'orderId': orderId}),
      );

      if (response.statusCode == 200) {
        final jsonRes = jsonDecode(response.body);
        return jsonRes['success'] == true;
      }
    } catch (e) {
      print("Lỗi hủy đơn: $e");
    }
    return false;
  }

  Future<bool> submitReviews(List<ReviewModel> reviews) async {
    // Đường dẫn API (Sửa lại IP máy bạn nếu cần)
    final token = await StorageHelper.getToken();
    final String url = '$urlEdit/api/reviews/add';

    try {
      List<Map<String, dynamic>> reviewsJson = reviews
          .map((e) => e.toJson())
          .toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"reviews": reviewsJson}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Lỗi Server trả về: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối API: $e");
      return false;
    }
  }

  // ================= AI CHAT =================
 Future<String> chatWithAI({
  required String question,
}) async {
  try {
    final token = await StorageHelper.getToken();
    final userId = await StorageHelper.getUserId();

    final url = Uri.parse('$urlEdit/api/ai/chat');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'prompt': question, // ✅ PHẢI LÀ prompt
        'user_id': userId,  // giữ hay bỏ đều được
      }),
    );

  if (response.statusCode == 200) {
    print('🔥 AI RAW RESPONSE: ${response.body}');
    final jsonRes = jsonDecode(response.body);

    return jsonRes['answer']?.toString() ?? 'AI chưa có câu trả lời';
  }
  else {
        return 'Lỗi AI (${response.statusCode})';
      }
    } catch (e) {
      return 'Không kết nối được AI';
    }
  }

  static Future<List<Promotion>> checkAvailablePromotions(List<CartItem> cartItems) async {
    try {
      final List<int> pIds = cartItems.map<int>((e) => e.productId).toList();
      final List<int> cIds = cartItems.map<int>((e) => e.categoryId).toList();

      final response = await http.post(
        Uri.parse('$urlEdit/api/promotions/check-available'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "productIds": pIds,     // Viết đúng CamelCase
          "categoryIds": cIds,    // Viết đúng CamelCase
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => Promotion.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Lỗi ApiService: $e");
      return [];
    }
  }

  // Lấy dữ liệu cho trang thông báo
  Future<Map<String, dynamic>> getNotificationSync() async {
    try {
      final token = await StorageHelper.getToken();
      final response = await http.get(
        Uri.parse('$urlEdit/api/notifications/sync'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      print('Error syncing notifications: $e');
      return {};
    }
  }

  // Lấy danh sách sản phẩm theo ID khuyến mãi
  Future<List<Product>> getProductsByPromotion(int promotionId) async {
    try {
      // Gọi vào endpoint mới mà bạn vừa viết ở Backend
      final url = Uri.parse('$urlEdit/api/promotions/$promotionId/products');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonRes = jsonDecode(response.body);
        
        if (jsonRes['success'] == true) {
          List<dynamic> data = jsonRes['data'];
          return data.map((json) => Product.fromJson(json)).toList();
        }
      } else {
        print("Lỗi server: ${response.statusCode}");
      }
      return [];
    } catch (e) {
      print("Lỗi khi lấy sản phẩm khuyến mãi: $e");
      return [];
    }
  }
}
