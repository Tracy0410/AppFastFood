import { execute, beginTransaction, commitTransaction, rollbackTransaction } from '../config/db.js';

class ReviewsModel{
    static async checkDrivedAndPAID(orderId,userId){
        console.log(userId);
        console.log(orderId);
        const sql = `
            SELECT order_id 
            FROM orders 
            WHERE order_id = ? 
            AND user_id = ? 
            AND order_status IN ('COMPLETED', 'DELIVERED', 'SUCCESS') -- Các trạng thái coi là hoàn thành
            AND payment_status = 'PAID' -- Bắt buộc đã thanh toán
        `;
        const [rows] = await execute(sql, [orderId, userId]);
        console.log(rows);
        return rows.length > 0;
    }

static async newComment(userId, orderId, productId, rating, comment) {
    let connection;
    try {
        connection = await beginTransaction();
        const insertSql = `
            INSERT INTO reviews 
            (user_id, order_id, product_id, rating, description, review_date, status) 
            VALUES (?, ?, ?, ?, ?, NOW(), 'active')
        `;
        await connection.execute(insertSql, [
            userId,
            orderId,
            productId,
            rating,
            comment
        ]);
        const updateProductSql = `
            UPDATE products
            SET 
                review_count = (
                    SELECT COUNT(*) FROM reviews 
                    WHERE product_id = ? AND status = 'active'
                ),
                average_rating = (
                    SELECT ROUND(AVG(rating), 1) FROM reviews 
                    WHERE product_id = ? AND status = 'active'
                )
            WHERE product_id = ?
        `;
        await connection.execute(updateProductSql, [
            productId,
            productId,
            productId
        ]);

        await commitTransaction(connection);
        return { success: true };
    } catch (error) {
        await rollbackTransaction(connection);
        console.log("Lỗi newComment:", error);
        throw error;
    }
}

}

export default ReviewsModel;