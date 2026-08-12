# Yummy Quick - Ứng dụng Đặt đồ ăn nhanh 🍔🍕

Dự án phát triển ứng dụng di động hỗ trợ đặt và giao đồ ăn nhanh, bao gồm hệ thống dành cho Khách hàng (User) và hệ thống Quản trị (Admin). Dự án được thiết kế với giao diện hiện đại, tối ưu trải nghiệm người dùng (UX/UI) và tích hợp các tính năng nâng cao như thanh toán, quản lý giỏ hàng, và Chatbot AI.

## 🚀 Công nghệ sử dụng (Tech Stack)
*   **Frontend (Mobile):** Flutter (Dart)
*   **Backend & API:** Node.js
*   **Cơ sở dữ liệu:** MySQL
*   **Design & Quản lý:** Figma, Git/GitHub, Clean Folder Structure

## 🌟 Các tính năng chính (Key Features)
### Dành cho Khách hàng (User App)
*   **Xác thực:** Đăng nhập, Đăng ký, và xác thực OTP qua Email.
*   **Khám phá sản phẩm:** Trang chủ (Home), Tìm kiếm & Gợi ý từ khóa, Lọc sản phẩm (theo giá, danh mục, đánh giá).
*   **Mua sắm:** Xem chi tiết sản phẩm, Thêm vào giỏ hàng, Mua hàng & Thanh toán.
*   **Quản lý cá nhân:** Lịch sử mua hàng, Theo dõi trạng thái đơn hàng, Lưu sản phẩm yêu thích, Quản lý Profile.
*   **Hỗ trợ:** Thông báo khuyến mãi/đơn hàng, FAQ, Liên hệ & Tích hợp Chatbox AI.

### Dành cho Quản trị viên (Admin Dashboard)
*   **Tổng quan:** Trang chủ Admin thống kê dữ liệu.
*   **Quản lý Đơn hàng:** Duyệt đơn, cập nhật trạng thái (Đơn mới, Đã duyệt, Thành công, Đã hủy).
*   **Quản lý Dữ liệu:** Quản lý danh sách Khách hàng và danh sách Sản phẩm.

---

## 👥 Đội ngũ Phát triển & Phân công công việc (Contributors)

Dự án được thực hiện bởi nhóm sinh viên với sự phân chia công việc theo mô hình Waterfall, đảm bảo từ khâu thiết kế (Figma), cấu hình cơ sở dữ liệu, phát triển API cho đến kiểm thử hệ thống.

### 1. Lâm Vũ Hoàng Châu - 0306231094 (Team Leader & UI/UX Developer)
*   **Quản lý dự án:** Setup hệ thống Git, tổ chức cấu trúc thư mục (Folder Structure), tổng hợp Báo cáo Đồ án (Vẽ ERD), chuẩn bị Video & Slide trình chiếu.
*   **Thiết kế (Figma):** Thiết kế toàn bộ giao diện người dùng (User Interface).
*   **Phát triển Frontend:** Code giao diện thanh điều hướng (Bottom Bar), màn hình Hỗ trợ/FAQ, Lọc sản phẩm, Khuyến mãi, Liên hệ & Chatbox AI.
*   **Kiểm thử & Tối ưu:** Thực hiện Unit Test (logic tính tiền), tối ưu UX & thêm các hiệu ứng Animation (Loading, Toast).

### 2. [Tên thành viên] - 0306231102 (Admin UI & API Developer)
*   **Thiết kế (Figma):** Thiết kế toàn bộ giao diện quản trị (Admin Interface).
*   **Phát triển Frontend & Backend:** Chỉnh sửa và tối ưu code API, code các màn hình Quản lý đơn hàng (duyệt đơn, đổi trạng thái), Trang chủ Admin, Quản lý sản phẩm và danh sách khách hàng.
*   **Tài liệu & Tối ưu:** Vẽ Class Diagram, chuẩn bị Slide trình chiếu, tối ưu UX & Animation.

### 3. [Tên thành viên] - 0306231096 (Backend API & Authentication)
*   **Cơ sở dữ liệu & API:** Viết Script DB, phát triển API Đăng nhập/Đăng ký & OTP qua email, API Yêu thích, API lấy dữ liệu nâng cao & xử lý Token chứng thực.
*   **Phát triển Frontend:** Code giao diện Login/Register, màn hình Thông báo, Profile & Cài đặt tài khoản.
*   **Quản lý & Kiểm thử:** Quản lý và xử lý phân nhánh Git (Branching), Unit Test logic tìm kiếm (Search), vẽ Activity Diagram, chuẩn bị Source code bàn giao.

### 4. [Tên thành viên] - 0306231095 (Frontend Core & Database)
*   **Cơ sở dữ liệu:** Cấu hình thư mục Data, Server và viết Script DB.
*   **Phát triển Frontend:** Code giao diện Trang chủ (Home), Chi tiết sản phẩm, Thanh tìm kiếm, Giỏ hàng, Mua hàng & Thanh toán, Xem chi tiết và Lịch sử đơn hàng.
*   **Kiểm thử & Tài liệu:** Thực hiện Unit Test (phân quyền Admin), vẽ UseCase Diagram, chuẩn bị Source code bàn giao.

---

## 📷 Hình ảnh Demo (Screenshots)
*   `![Home Screen] (https://drive.google.com/file/d/1WAOWS9iTKBn3ZoB6B9uX1pKfJE4Z8jYL/view?usp=drive_link)
*   `![Cart & Checkout] (https://drive.google.com/file/d/1N9uJzSOpwKrRM4AsJv60zoqpDfwXAOVD/view?usp=drive_link) & (https://drive.google.com/file/d/10Wce-Sn6tb1nMXDvHSjzbHQsavkO66vV/view?usp=drive_link)

## ⚙️ Hướng dẫn cài đặt (Installation)
1. Clone repository về máy:
   ```bash
   git clone [https://github.com/hoangchau28102004-cloud/AppFastFood.git](https://github.com/hoangchau28102004-cloud/AppFastFood.git)
