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
}

export default PromotionModel;