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
    
    static async getPromotionProducts(req, res) {
        try {
            const { id } = req.params;
            console.log(id);
            if (!id) {
                return res.status(400).json({
                    success: false,
                    message: 'Thiếu ID'
                });
            }

            const products = await PromotionModel.getProductsByPromotionId(id);
            return res.status(200).json({
                success: true,
                message: 'Lấy sản phẩm khuyến mãi thành công',
                count: products.length,
                data: products
            });
        } catch (error) {            
            return res.status(500).json({
                success: false,
                message: 'Lỗi server: ' + error.message
            });
        }
    }
}

export default PromotionController;