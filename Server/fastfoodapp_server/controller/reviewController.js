import ReviewsModel from '../models/reviewModel.js';

class ReviewsController{
    static async addReview (req, res){
    try {
        const userId = req.userId; 
        console.log(userId);
        const reviews = req.body.reviews; 
        console.log("Reviews nhận được:", reviews);

        if (!reviews || reviews.length === 0) {
            return res.status(400).json({ success: false, message: "Không có dữ liệu" });
        }
        for (const item of reviews) {
            const currentOrderId = item.order_id; 
            if (!userId || !currentOrderId || !item.product_id) {
                console.log("Bỏ qua item do thiếu dữ liệu:", item);
                continue; 
            }

            await ReviewsModel.newComment(
                userId,
                currentOrderId, 
                item.product_id,
                item.rating,
                item.comment || '',
            );
        }

        res.status(200).json({ success: true, message: "Đánh giá thành công!" });

    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(400).json({ 
                status: 'fail', 
                message: 'Bạn đã đánh giá sản phẩm này trong đơn hàng này rồi!' 
            });
        }
        console.log(error);
        return res.status(500).json({ status: 'error', message: error.message });
        }
    };
}

export default ReviewsController;