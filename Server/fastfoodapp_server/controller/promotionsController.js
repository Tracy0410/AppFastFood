import PromotionModel from '../models/promotionsModel.js';

class PromotionController {
    static async getPromotions(req, res) {
        try {
            const promotions = await PromotionModel.getAllActive();
            return res.status(200).json({
                success: true,
                message: 'Lấy danh sách khuyến mãi thành công',
                data: promotions
            });
        } catch (error) {
            console.error("Lỗi lấy khuyến mãi:", error);
            return res.status(500).json({
                success: false,
                message: 'Lỗi server'
            });
        }
    }
}

export default PromotionController;