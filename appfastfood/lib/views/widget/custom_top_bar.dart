import 'package:appfastfood/views/screens/users/cart_screen.dart';
import 'package:flutter/material.dart';

class CustomTopBar extends StatelessWidget {
  final bool isHome;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;

  final VoidCallback? onFilterTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  final int notificationCount;

  const CustomTopBar({
    super.key,
    this.isHome = false, // Mặc định là false
    this.searchController,
    this.onSearchChanged,
    this.onFilterTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFFFC529)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hàng Search và Icon
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: onSearchChanged,
                              decoration: InputDecoration(
                                hintText: "Search",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(bottom: 5),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onFilterTap, // Gọi hàm khi ấn
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE95322),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                    child: _buildIcon(Icons.shopping_cart_outlined),
                  ),

                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onNotificationTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildIcon(Icons.notifications_none),
                        if (notificationCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  notificationCount > 99 ? '99+' : '$notificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onProfileTap,
                    child: _buildIcon(Icons.person_outline),
                  ),
                ],
              ),

              // Logic hiển thị lời chào chỉ khi ở Home
              if (isHome) ...[
                const SizedBox(height: 20),
                const Text(
                  "Good Morning",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Nạp Năng Lượng Nào!",
                  style: TextStyle(
                    color: Color(0xFFE95322),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.3),
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Icon(icon, color: Colors.white, size: 20),
  );
}
