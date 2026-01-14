import { execute } from '../config/db.js';

class PromotionModel {
    static async getAllActive() {
        const sql = `
            SELECT 
                promotion_id, 
                name, 
                discount_percent, 
                start_date, 
                end_date 
            FROM Promotions 
            WHERE status = 1 
            AND end_date >= NOW()
            ORDER BY end_date ASC
        `;
        const [rows] = await execute(sql);
        return rows;
    }

    static async getProductsByPromotionId(promotionId) {
        const sql = `
            SELECT DISTINCT 
                p.product_id, 
                p.name, 
                p.price, 
                p.image_url, 
                p.description, 
                p.category_id, 
                c.name as category_name
            FROM Products p
            JOIN Categories c ON p.category_id = c.category_id
            JOIN Promotion_Details pd ON (
                (pd.product_id IS NOT NULL AND pd.product_id = p.product_id) -- Trùng ID sản phẩm
                OR 
                (pd.category_id IS NOT NULL AND pd.category_id = p.category_id) -- HOẶC Trùng ID danh mục
            )
            JOIN Promotions prom ON pd.promotion_id = prom.promotion_id
            
            WHERE pd.promotion_id = ? 
            AND p.status = 1
            AND pd.status = 1
            AND prom.status = 1
            AND prom.start_date <= NOW() 
            AND prom.end_date >= NOW();
        `;
        
        try {
            const [rows] = await execute(sql, [promotionId]);
            return rows;
        } catch (error) {
            throw error;
        }
    }
}

export default PromotionModel;