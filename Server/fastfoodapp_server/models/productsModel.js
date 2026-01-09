import { execute } from '../config/db.js';

class ProductModel {
    // 1. Lấy tất cả sản phẩm (Hàm bị thiếu gây lỗi)
    static async getAll() {
        const sql = `SELECT p.*, c.name as category_name FROM Products p JOIN Categories c ON p.category_id = c.category_id WHERE p.status = 1 ORDER BY p.product_id DESC`;
        const [rows] = await execute(sql);
        return rows;
    }

    // 2. Lấy chi tiết 1 sản phẩm
    static async getById(id) {
        const sql = `SELECT p.*, c.name as category_name FROM Products p JOIN Categories c ON p.category_id = c.category_id WHERE p.product_id = ?`;
        const [rows] = await execute(sql, [id]);
        return rows[0];
    }

    // 3. Lấy đánh giá của sản phẩm
    static async getReviewProductId(id) {
        const sql = `SELECT r.*, u.fullname, u.image FROM Reviews r JOIN Users u ON r.user_id = u.user_id WHERE r.product_id = ? ORDER BY r.review_date DESC`;
        const [rows] = await execute(sql, [id]);
        return rows;
    }

    // 4. Hàm Lọc sản phẩm (Đã bao gồm logic tính giá khuyến mãi)
    static async filter({ categoryId, minPrice, maxPrice, rating, keyword }) {
        let sql = `
            SELECT 
                p.*, 
                c.name as category_name,
                CAST(
                    CASE 
                        WHEN prom.discount_percent IS NOT NULL THEN p.price * (1 - prom.discount_percent / 100)
                        ELSE p.price 
                    END AS DECIMAL(15,2)
                ) AS final_price,
                prom.discount_percent
            FROM Products p
            JOIN Categories c ON p.category_id = c.category_id
            LEFT JOIN Promotion_Details pd ON (pd.product_id = p.product_id OR pd.category_id = p.category_id) AND pd.status = 1
            LEFT JOIN Promotions prom ON pd.promotion_id = prom.promotion_id 
                AND prom.status = 1 
                AND NOW() BETWEEN prom.start_date AND prom.end_date
            WHERE p.status = 1 AND c.status = 1
        `;
        
        const params = [];

        // Lọc danh mục
        if (categoryId && categoryId !== 'All' && categoryId !== '0') {
            sql += " AND p.category_id = ?";
            params.push(categoryId);
        }

        // Lọc Rating
        if (rating && Number(rating) > 0) {
            sql += " AND p.average_rating >= ?";
            params.push(Number(rating));
        }

        // Lọc giá (min - max)
        let havingClause = '';
        if (minPrice != null && maxPrice != null && minPrice !== '' && maxPrice !== '') {
            const min = Number(minPrice);
            const max = Number(maxPrice);
            if (!Number.isNaN(min) && !Number.isNaN(max)) {
                havingClause = ' HAVING final_price BETWEEN ? AND ?';
                params.push(min, max);
            }
        }

        sql += ' GROUP BY p.product_id';
        if (havingClause) sql += havingClause;

        sql += " ORDER BY p.product_id DESC";
        
        try {
            const [rows] = await execute(sql, params);
            return rows;
        } catch (error) {
            console.error("Lỗi SQL Filter:", error);
            return [];
        }
    }
}

export default ProductModel;