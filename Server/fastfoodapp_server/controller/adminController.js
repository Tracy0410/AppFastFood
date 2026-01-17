import userModel from '../models/userModel.js'; // Import Model bạn vừa sửa
import { execute } from '../config/db.js'; // Vẫn cần dùng cho hàm updateStatus (nếu chưa đưa vào model)

/**
 * API: Lấy danh sách đơn hàng cho Admin
 * Method: GET
 * Query: ?status=PENDING (hoặc để trống lấy tất cả)
 */
export const getAdminOrders = async (req, res) => {
    try {
        const { status } = req.query;

        console.log("👉 API getAdminOrders called with status:", status);

        // 1. Gọi hàm từ Model để lấy danh sách đơn hàng
        // (Model đã xử lý việc lọc status và sort ngày tháng)
        const orders = await userModel.getAllOrders(status);

        // Nếu không có đơn hàng nào
        if (!orders || orders.length === 0) {
            return res.status(200).json({ 
                success: true, 
                data: [] 
            });
        }

        // 2. Lấy chi tiết sản phẩm cho từng đơn hàng (Merge chi tiết vào đơn hàng)
        // Dùng Promise.all để chạy song song cho nhanh
        const ordersWithDetails = await Promise.all(orders.map(async (order) => {
            // Gọi hàm getOrderDetail từ Model
            const details = await userModel.getOrderDetail(order.order_id);
            
            return {
                ...order,
                order_details: details || []
            };
        }));

        res.status(200).json({ 
            success: true, 
            data: ordersWithDetails 
        });

    } catch (error) {
        console.error("❌ Error in getAdminOrders:", error);
        res.status(500).json({ 
            success: false, 
            message: "Lỗi Server khi lấy dữ liệu đơn hàng",
            error: error.toString() 
        });
    }
};

/**
 * API: Cập nhật trạng thái đơn hàng
 * Method: PUT
 * Body: { order_id, status }
 */
export const updateOrderStatus = async (req, res) => {
    try {
        const { order_id, status } = req.body;
        console.log(`👉 Updating Order #${order_id} to status: ${status}`);

        if (!order_id || !status) {
            return res.status(400).json({ 
                success: false, 
                message: "Thiếu order_id hoặc status" 
            });
        }

        // Validate status hợp lệ
        const validStatuses = ['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'];
        if (!validStatuses.includes(status)) {
             return res.status(400).json({ 
                success: false, 
                message: "Trạng thái không hợp lệ (Phải là: PENDING, PROCESSING, SHIPPED, DELIVERED, CANCELLED)" 
            });
        }

        // Thực thi Update (Lưu ý: Tên bảng phải khớp với Model là 'Orders')
        const sql = `UPDATE Orders SET order_status = ? WHERE order_id = ?`;
        const [result] = await execute(sql, [status, order_id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy đơn hàng để cập nhật"
            });
        }

        res.status(200).json({ 
            success: true, 
            message: "Cập nhật trạng thái thành công" 
        });

    } catch (error) {
        console.error("❌ Error in updateOrderStatus:", error);
        res.status(500).json({ 
            success: false, 
            message: "Lỗi Server khi cập nhật trạng thái",
            error: error.message 
        });
    }
};


//update payment status
export const updatePaymentStatus = async (req, res) => {
    try {
        const { order_id, payment_status } = req.body;
        console.log(`👉 Updating Order #${order_id} to r: ${payment_status}`);

        if (!order_id || !payment_status) {
            return res.status(400).json({ 
                success: false, 
                message: "Thiếu order_id hoặc payment_status" 
            });
        }

        // Validate payment status
        const validStatuses = ['PAID', 'UNPAID', 'PENDING', 'REFUNDED'];
        if (!validStatuses.includes(payment_status)) {
            return res.status(400).json({ 
                success: false, 
                message: "Trạng thái thanh toán không hợp lệ" 
            });
        }

        // SỬA: Bỏ updated_at nếu cột không tồn tại
        const sql = `UPDATE Orders SET payment_status = ? WHERE order_id = ?`;
        const [result] = await execute(sql, [payment_status, order_id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy đơn hàng để cập nhật"
            });
        }

        res.status(200).json({ 
            success: true, 
            message: "Cập nhật trạng thái thanh toán thành công" 
        });

    } catch (error) {
        console.error("❌ Error in updatePaymentStatus:", error);
        res.status(500).json({ 
            success: false, 
            message: "Lỗi Server khi cập nhật trạng thái thanh toán",
            error: error.message 
        });
    }
};
export const updateProductStatus = async (req, res) => {
  try {
    const { product_id, status } = req.body;

    console.log(`👉 Đang update Product ID: ${product_id} sang Status: ${status}`);

    if (!product_id) {
      return res.status(400).json({ success: false, message: 'Thiếu product_id' });
    }

    // Validate status phải là 0 hoặc 1
    if (status !== 0 && status !== 1) {
      return res.status(400).json({ success: false, message: 'Status phải là 0 hoặc 1' });
    }

    // Câu lệnh SQL cập nhật trạng thái
    const sql = "UPDATE Products SET status = ? WHERE product_id = ?";
    
    // Thực thi
    const [result] = await execute(sql, [status, product_id]);

    console.log("✅ Result:", result);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy sản phẩm' });
    }

    res.status(200).json({ 
      success: true, 
      message: status === 1 ? 'Đã hiện sản phẩm' : 'Đã ẩn sản phẩm'
    });
  } catch (error) {
    console.error("❌ Lỗi updateProductStatus:", error);
    res.status(500).json({ 
      success: false, 
      message: 'Lỗi Server khi ẩn/hiện sản phẩm' 
    });
  }
};
export const updateProduct = async (req, res) => {
    try {
        const { product_id, name, description, price, category_id, status } = req.body;
        
        console.log(`👉 Updating Product #${product_id}`, req.body);

        if (!product_id || !name || !description || !price || !category_id) {
            return res.status(400).json({ 
                success: false, 
                message: "Thiếu thông tin bắt buộc" 
            });
        }

        // SQL cập nhật sản phẩm
        const sql = `
            UPDATE Products 
            SET name = ?, description = ?, price = ?, category_id = ?, status = ?
            WHERE product_id = ?
        `;
        
        const [result] = await execute(sql, [
            name, 
            description, 
            price, 
            category_id, 
            status, 
            product_id
        ]);

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy sản phẩm để cập nhật"
            });
        }

        res.status(200).json({ 
            success: true, 
            message: "Cập nhật sản phẩm thành công" 
        });

    } catch (error) {
        console.error("❌ Error in updateProduct:", error);
        res.status(500).json({ 
            success: false, 
            message: "Lỗi Server khi cập nhật sản phẩm",
            error: error.message 
        });
    }
};
