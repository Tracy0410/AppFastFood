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
            -- 1. Join với Categories để lấy tên danh mục
            JOIN Categories c ON p.category_id = c.category_id
            
            -- 2. Join với Promotion_Details để lọc
            -- Logic: Sản phẩm được chọn NẾU (trùng ID sản phẩm) HOẶC (trùng ID danh mục)
            JOIN Promotion_Details pd ON (
                (pd.product_id IS NOT NULL AND pd.product_id = p.product_id) 
                OR 
                (pd.category_id IS NOT NULL AND pd.category_id = p.category_id)
            )
            
            -- 3. Đảm bảo khuyến mãi này còn hiệu lực
            JOIN Promotions prom ON pd.promotion_id = prom.promotion_id

            WHERE pd.promotion_id = ? 
            AND p.status = 1        -- Sản phẩm đang bán
            AND pd.status = 1       -- Chi tiết khuyến mãi đang bật
            AND prom.status = 1     -- Khuyến mãi gốc đang bật
            AND prom.start_date <= NOW() 
            AND prom.end_date >= NOW();
        `;

        try {
            console.log("🔍 Đang tìm sản phẩm cho Promo ID:", promotionId);
            const [rows] = await execute(sql, [promotionId]);
            console.log('✅ Kết quả: Tìm thấy ${rows.length} sản phẩm.');
            console.log(rows);
            return rows;
        } catch (error) {
            console.error("❌ Lỗi SQL getProductsByPromotionId:", error);
            throw error;
        }
    }
}

export default PromotionModel;