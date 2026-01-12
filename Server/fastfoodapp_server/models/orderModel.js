import { execute, beginTransaction, commitTransaction, rollbackTransaction } from '../config/db.js';

class Order{
    static async Order(userId){
        const query = `
        SELECT 
        o.order_id,     
        o.created_at,
        o.order_status,
        o.payment_status,
        o.total_amount,
        
        -- Lấy phương thức thanh toán
        (SELECT method FROM Payment WHERE order_id = o.order_id ORDER BY payment_time DESC LIMIT 1) as payment_method,
        
        -- Tóm tắt món ăn (Ví dụ: Gà x2, Coca x1)
        GROUP_CONCAT(CONCAT(p.name, ' (x', od.quantity, ') - ', (p.price * od.quantity)) SEPARATOR ', ') as items_summary,
        
        -- Ảnh đại diện (Lấy ảnh món đầu tiên)
        (SELECT image_url FROM Products p2 JOIN Order_Details od2 ON p2.product_id = od2.product_id WHERE od2.order_id = o.order_id LIMIT 1) as thumbnail

        FROM Orders o
        JOIN Order_Details od ON o.order_id = od.order_id
        JOIN Products p ON od.product_id = p.product_id
        WHERE o.user_id = ?
        GROUP BY o.order_id
        ORDER BY o.created_at DESC;
    `;

    const [rows] = await execute(query, [userId]);
    console.log(rows);
    return rows;
        }
        static async OrderDetalById(userId,orderId){
            const query = `
        SELECT 
            o.order_id, 
            o.created_at, 
            o.order_status, 
            o.payment_status,
            o.subtotal,            
            o.discount_amount,     
            o.tax_fee,             
            o.total_amount,        
            
            (SELECT method FROM Payment WHERE order_id = o.order_id ORDER BY payment_time DESC LIMIT 1) as payment_method,
            
            -- LẤY FULL DANH SÁCH TÊN MÓN
            GROUP_CONCAT(CONCAT(p.name, ' (x', od.quantity, ') - ', (p.price * od.quantity)) SEPARATOR ', ') as items_summary,
            
            (SELECT image_url FROM Products p2 JOIN Order_Details od2 ON p2.product_id = od2.product_id WHERE od2.order_id = o.order_id LIMIT 1) as thumbnail

        FROM Orders o
        JOIN Order_Details od ON o.order_id = od.order_id
        JOIN Products p ON od.product_id = p.product_id
        WHERE o.order_id = ? AND o.user_id = ?
        GROUP BY o.order_id;
    `;

    const [rows] = await execute(query, [orderId, userId]);
    console.log(rows);
    return rows[0]; // Chỉ trả về 1 object (hoặc undefined nếu ko tìm thấy)
    };

    // --- 3. KIỂM TRA ĐƠN ĐỂ THANH TOÁN LẠI ---
    static async checkOrderForPayment(orderId, userId){
        const query = `
            SELECT total_amount
            FROM Orders
            WHERE order_id = ? AND user_id = ?
            AND payment_status = 'UNPAID'
            AND order_status != 'CANCELLED'
        `;
        const [rows] = await execute(query, [orderId, userId]);
        return rows[0];
    }

    // Lấy đơn hàng mới nhất của User để hiện thông báo
    static async getLatestOrder(userId) {
        const query = `
            SELECT 
                order_id, 
                order_status, 
                payment_status, 
                total_amount,
                created_at 
            FROM Orders 
            WHERE user_id = ? 
            ORDER BY created_at DESC 
            LIMIT 1; -- Chỉ lấy 1 đơn mới nhất
        `;
        const [rows] = await execute(query, [userId]);
        return rows[0];
    }
}

export default Order;