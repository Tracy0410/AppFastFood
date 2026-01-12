import OrderModel from '../models/orderModel.js';
import userModel from '../models/userModel.js';
class OderControllder{
    static async getMyOrders(req, res){
    try {
        const userId = req.userId;
        console.log(userId);

        const orders = await OrderModel.Order(userId);

        if (!orders || orders.length === 0) {
        return res.status(200).send({ success: true, data: [], message: "Chưa có đơn hàng nào" });
        }
        res.send({
        success: true,
        data: orders
        });
    } catch (err) {
        console.log("Lỗi lấy đơn hàng:", err);
        res.status(500).send({ message: "Lỗi server khi tải đơn hàng." });
    }
    }
    static async getOrderDetail(req, res){
  try {
    const userId = req.userId;
    const orderId = req.params.id; // Lấy ID từ URL (vd: /api/orders/15)
    console.log(orderId);
    console.log(userId);
    console.log(orderId);
    const order = await OrderModel.OrderDetalById(userId, orderId);

    if (!order) {
      return res.status(404).send({ message: "Không tìm thấy đơn hàng hoặc bạn không có quyền xem." });
    }

    res.send({
      success: true,
      data: order
    });

  } catch (err) {
    console.log("Lỗi lấy chi tiết:", err);
    res.status(500).send({ message: "Lỗi server." });
  }
};

// --- C. XỬ LÝ THANH TOÁN LẠI (Repayment VNPay) ---
static async retryPayment(req, res) {
    try {
        const userId = req.userId;
        const { orderId } = req.body;

        // 1. Kiểm tra đơn hàng có hợp lệ để thanh toán không
        const order = await OrderModel.checkOrderForPayment(orderId, userId);
        
        if (!order) {
            return res.status(400).send({ message: "Đơn hàng không tồn tại hoặc đã thanh toán/đã hủy." });
        }
        const result = await userModel.updatePaymentStatus(orderId,'PAID');
        if(result){
          res.status(200).send({
            success: true,
            message: "Thanh toán thành công (Test Mode)"
          });
        }else {
          res.status(500).send({ success: false, message: "Lỗi cập nhật DB" });
        }

    } catch (err) {
        console.log(err);
        res.status(500).send({ success: false, message: "Lỗi Server: " + err.message });
    }
}

static async cancelOrder(req, res) {
    try {
        const userId = req.userId;
        const { orderId } = req.body;

        const isCancelled = await OrderModel.cancelOrder(orderId, userId);

        if (isCancelled) {
            res.status(200).json({ success: true, message: "Đã hủy đơn hàng thành công." });
        } else {
            res.status(400).json({ 
                success: false, 
                message: "Không thể hủy đơn hàng này (Đã được xác nhận hoặc đã thanh toán)." 
            });
        }
    } catch (err) {
        res.status(500).json({ success: false, message: "Lỗi server: " + err.message });
    }
}
}



export default OderControllder;
