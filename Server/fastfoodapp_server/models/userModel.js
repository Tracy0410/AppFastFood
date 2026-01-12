import { execute, beginTransaction, commitTransaction, rollbackTransaction } from '../config/db.js';

export default class userModel {
    // Tìm user để đăng nhập (Join giữa Account và Users)
    static async findByUsername(username) {
        try {
            const sql = `
                SELECT 
                    a.account_id, a.Username, a.password, a.role, a.status,
                    u.user_id, u.fullname, u.email, u.phone, u.Image
                FROM Account a
                LEFT JOIN Users u ON a.account_id = u.account_id
                WHERE a.Username = ? 
                LIMIT 1
            `;
            const [rows] = await execute(sql, [username]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error('Database query failed: ' + error.message);
        }
    }

    // Đăng ký tài khoản mới (Sử dụng Transaction)
    static async create({ username, hashedPassword, fullname, email, phone }) {
        let connection;
        try {
            // 1. Bắt đầu transaction
            connection = await beginTransaction();

            // 2. Thêm vào bảng Account
            const [accountResult] = await connection.execute(
                'INSERT INTO Account(Username, password, role, status) VALUES(?, ?, ?, ?)',
                [username, hashedPassword, 'CUSTOMER', 1]
            );
            const accountId = accountResult.insertId;

            // 3. Thêm vào bảng Users
            await connection.execute(
                'INSERT INTO Users(account_id, fullname, email, phone) VALUES(?, ?, ?, ?)',
                [accountId, fullname, email, phone]
            );

            // 4. Commit (Lưu thay đổi)
            await commitTransaction(connection);
            
            return accountId;
        } catch (error) {
            // 5. Rollback nếu có lỗi (Hủy thay đổi)
            if (connection) await rollbackTransaction(connection);
            throw new Error('Registration failed: ' + error.message);
        }
    }

    // Tìm user bằng ID (dùng cho profile)
    static async findById(id) {
        try {
            
             const sql = `
                SELECT 
                    a.account_id, a.Username, a.role,
                    u.user_id, u.fullname, u.email, u.phone, u.BirthDay, u.Image
                FROM Account a
                LEFT JOIN Users u ON a.account_id = u.account_id
                WHERE a.account_id = ?
            `;
            const [rows] = await execute(sql, [id]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error('Database query failed: ' + error.message);
        }
    }

    // Cập nhật thông tin user
    static async updateUser(userId, updateData) {
        try {
            const fields = [];
            const values = [];

            if (updateData.fullname) {
                fields.push('fullname = ?');
                values.push(updateData.fullname);
            }
            if (updateData.email) {
                fields.push('email = ?');
                values.push(updateData.email);
            }
            if (updateData.phone) {
                fields.push('phone = ?');
                values.push(updateData.phone);
            }
            if (updateData.birthday) {
                fields.push('BirthDay = ?');
                values.push(updateData.birthday);
            }
            if (updateData.image) {
                fields.push('Image = ?');
                values.push(updateData.image);
            }

            if (fields.length === 0) return { success: false, message: "Không có dữ liệu để cập nhật" };

            values.push(userId);
            const sql = `UPDATE Users SET ${fields.join(', ')} WHERE user_id = ?`;
            
            const [result] = await execute(sql, values);
            return { success: true, affectedRows: result.affectedRows };

        } catch (error) {
            throw new Error('Update user failed: ' + error.message);
        }
    }

    // Lấy danh sách địa chỉ của User
    static async getAddressByUserId(userId){
        try{
            const sql=`
                SELECT a.* FROM users u 
                JOIN addresses a ON u.user_id = a.user_id
                WHERE u.user_id = ?
            `;
            const [rows] = await execute(sql,[userId]);
            return rows;
        }catch(e){
            throw e;
        }
    }

    // Thêm địa chỉ mới
    static async addAddresses({ userId, name, street, district, city }) {
        // 1. Bắt đầu Transaction
        let connection = await beginTransaction();
        try {
            // 2. Kiểm tra xem địa chỉ này đã tồn tại trong database chưa
            const checkSql = `SELECT address_id, status FROM Addresses WHERE user_id = ? 
                AND street_address = ? AND district = ? AND city = ? LIMIT 1`;
            
            const [rows] = await connection.execute(checkSql, [userId, street, district, city]);

            if (rows.length > 0) {
                const existingAddress = rows[0];

                if (existingAddress.status == 1) {
                    // a. Nếu status đang là 1 (Active) -> Báo lỗi trùng
                    throw new Error('Địa chỉ này đã tồn tại trong danh sách của bạn!');
                } else {
                    // b. Nếu status đang là 0 (Đã xóa/Ẩn) -> Khôi phục lại
                    await connection.execute(
                        `UPDATE Addresses SET status = 1, recipient_name = ? 
                         WHERE address_id = ?`,
                        [name, existingAddress.address_id]);
                }
            } else {
                await connection.execute(
                    `INSERT INTO Addresses(user_id, recipient_name, street_address, district, city, is_default, status) 
                     VALUES (?, ?, ?, ?, ?, 0, 1)`,
                    [userId, name, street, district, city]
                );
            }

            // 3. Commit thay đổi
            await commitTransaction(connection);
            return true;

        } catch (e) {
            if (connection) await rollbackTransaction(connection);
            throw new Error(e.message);
        }
    }

    // Chỉnh chế độ địa chỉ
    static async setDefaultAddress(userId, addressId) {
        // 1. Bắt đầu Transaction
        let connection = await beginTransaction();
        try {
            // 2. Reset tất cả địa chỉ của User này về 0
            await connection.execute(`UPDATE Addresses SET is_default = 0 WHERE user_id = ?`, [userId]);

            // 3. Set địa chỉ được chọn thành 1
            const [result] = await connection.execute(
                `UPDATE Addresses SET is_default = 1 WHERE address_id = ? AND user_id = ?`,
                [addressId, userId]
            );

            // Kiểm tra xem có dòng nào được update không
            if (result.affectedRows === 0) {
                await rollbackTransaction(connection);
                return false; 
            }

            // 4. Commit thay đổi
            await commitTransaction(connection);
            return true;

        } catch (error) {
            if (connection) await rollbackTransaction(connection);
            throw new Error(error.message);
        }
    }

    // Xóa địa chỉ
    static async deleteAddresses(userId, addressId){
        let connection = await beginTransaction();
        try{
            const [result] = await connection.execute(
                `UPDATE Addresses SET status = 0 WHERE address_id = ? AND user_id = ?`,
                [addressId, userId] 
            );

            if (result.affectedRows === 0) {
                await rollbackTransaction(connection);
                throw new Error("Không tìm thấy địa chỉ hoặc bạn không có quyền xóa");
            }

            await commitTransaction(connection);
            return true;
        }catch(e){
            if(connection) await rollbackTransaction(connection);
            throw new Error(e.message);
        }
    }

    // Thêm sản phẩm yêu thích
    static async addFavorites(userId,productId){
        try{
            const [check] = await execute('SELECT * FROM favorites WHERE user_id = ? AND product_id = ?', [userId,productId]);
            if(check.length > 0){
                return { success: false, message: 'Sản phẩm này đã thích rồi' };
            }
            const [result] = await execute('INSERT INTO favorites(user_id,product_id,liked_at) VALUES(?,?,NOW())',
                [userId,productId]
            );
            return { success: true, message:"Vừa thích sản phẩm này" };
        }catch(e){
            console.error("Lỗi model Add Favorites")
            throw e;
        }
    }

    // Kiểm tra sản phẩm đã được yêu thích chưa
    static async checkFavorites(userId,productId){
        const [rows] = await execute('SELECT * FROM favorites WHERE user_id = ? AND product_id = ?',[userId,productId]);
        return rows.length > 0;
    }

    // Xóa sản phẩm yêu thích
    static async removeFavorites(userId,product_id){
        try {
            const [result] = await execute('DELETE FROM favorites WHERE user_id = ? AND product_id = ?',[userId,product_id]);
            return result.affectedRows > 0;
        } catch (error) {
            throw error;
        }
    }

    // Lấy danh sách sản phẩm yêu thích của User
    static async getFavoritesByUserId(userId) {
        try {
            const sql = `
                SELECT p.* FROM Products p
                JOIN Favorites f ON p.product_id = f.product_id
                JOIN Users u ON f.user_id = u.user_id
                WHERE u.user_id = ?
            `;
            const [rows] = await execute(sql, [userId]);
            return rows;
        } catch (error) {
            throw error;
        }
    }

    // Tìm user bằng Email để gửi OTP
    static async findByEmail(email) {
        try {
            const sql = `
                SELECT 
                    a.account_id, a.Username, a.status,
                    u.user_id, u.fullname, u.email
                FROM Users u
                JOIN Account a ON u.account_id = a.account_id
                WHERE u.email = ?
            `;
            const [rows] = await execute(sql, [email]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error('Database query failed: ' + error.message);
        }
    }

    // Cập nhật mật khẩu mới
    static async updatePassword(accountId, newHashedPassword) {
        try {
            const sql = 'UPDATE Account SET password = ? WHERE account_id = ?';
            await execute(sql, [newHashedPassword, accountId]);
            return true;
        } catch (error) {
            throw new Error('Update password failed: ' + error.message);
        }
    }
    // Hàm này nhiều quá lười try catch deadline dí (T_T)
    static async checkItemInCart(user_id,product_id){
        const sql = `SELECT * FROM carts WHERE user_id = ? AND product_id = ?`;
        const [rows] = await execute(sql,[user_id,product_id]);
        return rows[0];
    }

    static async addToCart(user_id,product_id,quantity,note){
        const sql = `INSERT INTO carts(user_id,product_id,quantity,note)
        VALUES (?,?,?,?)
        `;
        return await execute(sql,[user_id,product_id,quantity,note]);
    }

    static async updateCart(cartId,quantity,note){
    const sql = `UPDATE carts SET quantity = ?, note = ?, updated_at = NOW() WHERE cart_id = ?`;
    
    return await execute(sql, [quantity, note, cartId]);
    }

    static async getCartByUserId(userId){
        const sql = `
        SELECT c.cart_id, c.product_id, c.quantity, c.note, p.name, p.price, p.image_url 
        FROM Carts c
        JOIN Products p ON c.product_id = p.product_id
        WHERE c.user_id = ?
        `;
        const [rows] = await execute(sql,[userId]);
        return rows;
    }

    static async removeCartItem(cartId){
        const sql = `DELETE FROM carts WHERE cart_id = ?`;
        return await execute(sql,[cartId]);
    }

    static async calculateOrderRaw(connection, items, promotionId, shippingAddressId) {
        let promotion = null;
        let promotionDetails = [];

        // 1. Lấy thông tin Voucher (Nếu có)
        if (promotionId) {
            const [promos] = await connection.execute(
                `SELECT * FROM promotions WHERE promotion_id = ? AND status = 1 AND start_date <= NOW() AND end_date >= NOW()`,
                [promotionId]
            );
            if (promos.length > 0) {
                promotion = promos[0];
                const [details] = await connection.execute(
                    `SELECT promotion_id, product_id, category_id, promotion_detail_id FROM promotion_details WHERE promotion_id = ? AND status = 1`,
                    [promotionId]
                );
                promotionDetails = details;
            }
        }

        // 2. Tính toán từng món hàng
        let subtotal = 0;
        let totalDiscountAmount = 0;
        const calculatedItems = [];

        for (const item of items) {
            // Luôn query lại giá mới nhất từ DB để bảo mật (tránh hack giá từ client)
            const [products] = await connection.execute(
                `SELECT product_id, name, price, category_id, image_url FROM Products WHERE product_id = ?`,
                [item.productId] // Lưu ý: Client gửi lên key là 'productId'
            );

            if (products.length === 0) throw new Error(`Sản phẩm ID ${item.productId} không tồn tại`);

            const product = products[0];
            const unitPrice = parseFloat(product.price);
            const quantity = item.quantity;
            const lineTotalOrigin = unitPrice * quantity;

            subtotal += lineTotalOrigin;

            // Logic tính giảm giá
            let discountForThisItem = 0;
            let appliedDetailId = null;

            if (promotion) {
                let matchedDetail = promotionDetails.find(d => d.product_id == product.product_id);
                if (!matchedDetail) matchedDetail = promotionDetails.find(d => d.category_id == product.category_id);

                // Logic: Có detail khớp HOẶC Voucher áp dụng toàn bộ (không có detail con)
                if (matchedDetail || promotionDetails.length === 0) {
                    const percent = parseFloat(promotion.discount_percent);
                    discountForThisItem = (lineTotalOrigin * percent) / 100;
                    if (matchedDetail) appliedDetailId = matchedDetail.promotion_detail_id;
                }
            }

            totalDiscountAmount += discountForThisItem;

            calculatedItems.push({
                product_id: product.product_id,
                name: product.name,
                image: product.image_url,
                quantity: quantity,
                unit_price: unitPrice,
                final_line_price: lineTotalOrigin - discountForThisItem,
                promotion_detail_id: appliedDetailId
            });
        }

        // 3. Phí Ship & Thuế
        // Giả sử phí ship cố định, hoặc bạn query bảng Address để tính
        let shippingFee = shippingAddressId ? 15000 : 0; 
        
        // Thuế 8% (Ví dụ) trên số tiền sau khi giảm giá
        const taxRate = 0.08; 
        const taxableAmount = subtotal - totalDiscountAmount;
        const taxFee = taxableAmount * taxRate;

        // Tổng tiền cuối cùng
        let totalAmount = taxableAmount + taxFee + shippingFee;
        if (totalAmount < 0) totalAmount = 0;

        return {
            subtotal,
            totalDiscountAmount,
            shippingFee,
            taxFee,
            totalAmount,
            promotionId: promotion ? promotion.promotion_id : null,
            items: calculatedItems
        };
    }

    /**
     * API 1: XEM TRƯỚC ĐƠN HÀNG (Preview)
     * Gọi hàm này khi vừa vào màn hình Checkout để hiển thị số liệu
     */
    static async previewOrder(items, promotionId, shippingAddressId) {
        let connection;
        try {
            // Lấy connection từ pool (không cần beginTransaction vì chỉ đọc)
            connection = await execute('SELECT 1'); // Hack nhỏ để lấy connection object nếu hàm execute của bạn chỉ trả rows. 
            // Tốt nhất bạn nên export pool từ db.js để dùng getConnection(), 
            // nhưng ở đây tôi dùng hàm execute wrapper nên ta sẽ giả lập logic của calculateOrderRaw chấp nhận execute wrapper.
            // *Lưu ý*: Để code `calculateOrderRaw` chạy được với `execute` wrapper của bạn, tôi sẽ sửa lại logic gọi DB một chút bên dưới nếu cần.
            // Nhưng cách tốt nhất ở đây là tái sử dụng logic.
            
            // Ở đây tôi giả định bạn có thể import pool. Nếu không, tôi viết lại hàm calculate chạy độc lập transaction:
             
            // -- FIX: Viết logic chạy trực tiếp --
            return await this.calculateOrderRaw({ execute: execute }, items, promotionId, shippingAddressId);
            
        } catch (error) {
            throw error;
        }
    }

    static async createOrderTransaction({ userId, shippingAddressId, note, items, isBuyFromCart = false, promotionId = null, paymentMethod = 'COD' }) {
        let connection;
        try {
            connection = await beginTransaction(); // Bắt đầu Transaction thật

            // 1. Tính toán lại lần cuối (Bảo mật giá)
            // Truyền connection vào để nó dùng chung transaction này
            const calc = await userModel.calculateOrderRaw(connection, items, promotionId, shippingAddressId);

            // 2. Insert bảng Orders
            const [orderResult] = await connection.execute(
                `INSERT INTO Orders (
                    user_id, promotion_id, shipping_address_id, 
                    subtotal, discount_amount, tax_fee, total_amount, 
                    order_status, payment_status, note, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, 'PENDING', 'UNPAID', ?, NOW())`,
                [
                    userId, 
                    calc.promotionId, 
                    shippingAddressId, 
                    calc.subtotal, 
                    calc.totalDiscountAmount, 
                    calc.taxFee, 
                    calc.totalAmount, 
                    note
                ]
            );
            const newOrderId = orderResult.insertId;

            // 3. Insert bảng Order_Details
            for (const item of calc.items) {
                await connection.execute(
                    `INSERT INTO Order_Details(order_id, product_id, quantity, unit_price, promotion_detail_id, final_line_price)
                     VALUES (?,?,?,?,?,?)`,
                    [newOrderId, item.product_id, item.quantity, item.unit_price, item.promotion_detail_id, item.final_line_price]
                );
            }

            // 4. Insert Payment (Lưu phương thức thanh toán) - QUAN TRỌNG
            await connection.execute(
                `INSERT INTO Payment(order_id, user_id, method, amount, status, payment_time) 
                 VALUES (?, ?, ?, ?, 'PENDING', NOW())`,
                [newOrderId, userId, paymentMethod, calc.totalAmount]
            );

            // 5. Xóa giỏ hàng (Nếu mua từ giỏ)
            if (isBuyFromCart && items.length > 0) {
                const productIds = items.map(i => i.product_id); // calc.items đã chuẩn hóa key
                // Tạo string (?,?,?) dynamic
                const placeholders = productIds.map(() => '?').join(',');
                const deleteParams = [userId, ...productIds];
                
                await connection.execute(
                    `DELETE FROM Carts WHERE user_id = ? AND product_id IN (${placeholders})`,
                    deleteParams
                );
            }

            await commitTransaction(connection);

            return {
                success: true,
                order_id: newOrderId,
                total_amount: calc.totalAmount,
                message: "Đặt hàng thành công"
            };

        } catch (e) {
            if (connection) await rollbackTransaction(connection);
            console.error("Lỗi Create Order Transaction:", e);
            throw new Error(e.message);
        }
    }

    static async checkAddressById(userId){
        try {
            
            const [rows] = await execute(`
                SELECT * FROM Addresses where user_id = ?`,[userId]);
            return rows;
        } catch (error) {
            console.error("Lỗi check address",error);
            throw new Error(error.message);
        }
    }
       // --- LẤY TẤT CẢ ĐƠN HÀNG (ADMIN) - CÓ HỖ TRỢ LỌC STATUS ---
   static async getAllOrders(status) {
    try {
        let sql = `
            SELECT 
                o.order_id, 
                o.user_id, 
                o.total_amount, 
                o.order_status, 
                o.payment_status,
                o.created_at, 
                o.note,
                o.subtotal,
                o.discount_amount,
                o.shipping_address_id,
                u.fullname,
                u.email,
                u.phone,
                a.recipient_name,
                a.street_address,
                a.district,
                a.city
            FROM Orders o
            JOIN Users u ON o.user_id = u.user_id
            LEFT JOIN Addresses a ON o.shipping_address_id = a.address_id
            WHERE 1=1
        `;
            
            const params = [];

            // Logic lọc động ở đây
            if (status && status !== 'ALL' && status.trim() !== '') {
                sql += ` AND o.order_status = ?`;
                params.push(status.trim());
            }

            sql += ` ORDER BY o.created_at DESC`;

            const [rows] = await execute(sql, params);
            return rows;
        } catch (error) {
            throw new Error('Get all orders failed: ' + error.message);
        }
    }

    // 2. Lấy đơn hàng theo User ID (App User)
    static async getOrdersByUserId(userId) {
        const sql = `
            SELECT 
                order_id, 
                total_amount, 
                order_status, 
                payment_status,
                created_at, 
                note 
            FROM Orders 
            WHERE user_id = ? 
            ORDER BY created_at DESC
        `;
        const [rows] = await execute(sql, [userId]);
        return rows;
    }

    // 3. Lấy chi tiết sản phẩm trong một đơn hàng
    static async getOrderDetail(orderId) {
        const sql = `
            SELECT 
                od.detail_id, 
                od.product_id, 
                od.quantity, 
                od.final_line_price as price, 
                p.name, 
                p.image_url 
            FROM Order_Details od
            JOIN Products p ON od.product_id = p.product_id
            WHERE od.order_id = ?
        `;
        const [rows] = await execute(sql, [orderId]);
        return rows;
    }
    
    // 4. Lấy thông tin chung của 1 đơn hàng cụ thể
     static async getOrderById(orderId) {
        const sql = `SELECT * FROM Orders WHERE order_id = ?`;
        const [rows] = await execute(sql, [orderId]);
        return rows[0];
    }

}