import userModel from '../models/userModel.js'; 
import { execute } from '../config/db.js'; 

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
        const orders = await userModel.getAllOrders(status);
        
        // Nếu không có đơn hàng nào
        if (!orders || orders.length === 0) {
            return res.status(200).json({ 
                success: true, 
                data: [] 
            });
        }

        // 2. Lấy chi tiết sản phẩm cho từng đơn hàng
        // SỬA LỖI: Không được log 'ordersWithDetails' bên trong vòng lặp này
        const ordersWithDetails = await Promise.all(orders.map(async (order) => {
            // Gọi hàm getOrderDetail từ Model
            const details = await userModel.getOrderDetail(order.order_id);
            
            // Log kiểm tra từng chi tiết đơn (nếu cần)
            console.log(`Chi tiết đơn ${order.order_id}:`, details);
            
            return {
                ...order,
                order_details: details || []
            };
        }));

        // ✅ Log kết quả SAU KHI đã tạo xong biến
        console.log("✅ Final Orders Data:", JSON.stringify(ordersWithDetails, null, 2));

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

        // Thực thi Update
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