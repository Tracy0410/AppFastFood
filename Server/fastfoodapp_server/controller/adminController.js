import userModel from '../models/userModel.js'; // Import Model bạn vừa sửa
import ProductModel from '../models/productsModel.js';
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

export const getAdminProducts = async (req, res) => {
    try {
        // Lấy tham số từ URL
        const { status, category_id } = req.query;
        
        console.log("👉 Admin fetching products filter:", { status, category_id });

        // Gọi hàm getAdminProducts trong Model (Đã viết ở trên)
        // Lưu ý: Không truyền req, res vào Model
        const products = await ProductModel.getAdminProducts({ 
            status, 
            categoryId: category_id 
        });

        res.status(200).json({
            success: true,
            message: "Lấy danh sách sản phẩm thành công",
            data: products
        });
    } catch (error) {
        console.error("❌ Error in getAdminProducts:", error);
        res.status(500).json({ 
            success: false, 
            message: "Lỗi Server khi lấy danh sách sản phẩm",
            error: error.message 
        });
    }
};

export const updateProduct = async (req, res) => {
    try {
        const { product_id, name, description, price, category_id, status, image } = req.body;
        
        console.log(`👉 Updating Product #${product_id}`, req.body);

        if (!product_id) {
            return res.status(400).json({ 
                success: false, 
                message: "Thiếu product_id" 
            });
        }

        let finalImage = req.body.image;
        if (req.file) {
            const b64 = Buffer.from(req.file.buffer).toString('base64');
            const mimeType = req.file.mimetype;
            finalImage = `data:${mimeType};base64,${b64}`;
        }

        // Gọi hàm update dynamic từ Model
        const result = await ProductModel.updateProduct(product_id, {
            name, 
            description, 
            price, 
            category_id, 
            status, 
            image: finalImage
        });

        if (result.affectedRows === 0) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy sản phẩm hoặc dữ liệu không thay đổi"
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
