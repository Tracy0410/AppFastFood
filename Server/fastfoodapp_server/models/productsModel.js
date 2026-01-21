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
            c.name as category_name
        FROM Products p
        JOIN Categories c ON p.category_id = c.category_id
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

    // Lọc giá gốc (min - max)
    if (maxPrice != null && maxPrice !== '') {
        const max = Number(maxPrice);
        const min = minPrice != null && minPrice !== '' ? Number(minPrice) : 0;
        if (!Number.isNaN(min) && !Number.isNaN(max)) {
            sql += " AND p.price BETWEEN ? AND ?";
            params.push(min, max);
        }
    }

    sql += " ORDER BY p.product_id DESC";

    try {
        const [rows] = await execute(sql, params);
        return rows;
    } catch (error) {
        console.error("Lỗi SQL Filter:", error);
        return [];
    }
}

    static async getAdminProducts({ status, categoryId }) {
        try {
            let sql = `
                SELECT p.*, c.name as category_name 
                FROM Products p 
                LEFT JOIN Categories c ON p.category_id = c.category_id
            `;
            
            const params = [];
            const conditions = [];

            // Điều kiện 1: Lọc theo trạng thái (0: Ẩn, 1: Hiện) - Nếu không truyền thì lấy tất cả
            if (status !== undefined && status !== null && status !== '') {
                conditions.push("p.status = ?");
                params.push(status);
            }

            // Điều kiện 2: Lọc theo danh mục
            if (categoryId && categoryId !== 'All' && categoryId !== '0') {
                conditions.push("p.category_id = ?");
                params.push(categoryId);
            }

            // Gắn điều kiện vào câu SQL
            if (conditions.length > 0) {
                sql += " WHERE " + conditions.join(" AND ");
            }

            sql += " ORDER BY p.product_id DESC"; // Mới nhất lên đầu

            const [rows] = await execute(sql, params);
            return rows;
        } catch (error) {
            throw new Error('Database Error: ' + error.message);
        }
    }

    static async updateProduct(productId, updateData) {
        try {
            const fields = [];
            const values = [];

            // Kiểm tra từng trường, trường nào có dữ liệu mới thêm vào câu lệnh Update
            if (updateData.name !== undefined) {
                fields.push('name = ?');
                values.push(updateData.name);
            }
            if (updateData.description !== undefined) {
                fields.push('description = ?');
                values.push(updateData.description);
            }
            if (updateData.price !== undefined) {
                fields.push('price = ?');
                values.push(updateData.price);
            }
            if (updateData.category_id !== undefined) {
                fields.push('category_id = ?');
                values.push(updateData.category_id);
            }
            if (updateData.status !== undefined) { 
                fields.push('status = ?'); // Cập nhật trạng thái (0 hoặc 1)
                values.push(updateData.status);
            }
            if (updateData.image !== undefined) {
                fields.push('image_url = ?');
                values.push(updateData.image);
            }

            // Nếu không gửi lên trường nào thì báo lỗi hoặc return
            if (fields.length === 0) {
                return { affectedRows: 0 };
            }

            values.push(productId); // Tham số cuối cùng cho WHERE product_id = ?
            
            const sql = `UPDATE Products SET ${fields.join(', ')} WHERE product_id = ?`;
            
            const [result] = await execute(sql, values);
            return result;

        } catch (error) {
            throw new Error('Update failed: ' + error.message);
        }
    }

}

export default ProductModel;