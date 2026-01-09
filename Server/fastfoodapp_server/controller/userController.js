import { hash, compare } from 'bcrypt';
import jwt from 'jsonwebtoken';
import userModel from '../models/userModel.js';
import dotenv from 'dotenv';
import nodemailer from 'nodemailer';
dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '8h';
const PASSWORD_HASH_ROUNDS = parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10;

const otpStore = new Map();
// Cấu hình gửi mail (Dùng Gmail hoặc SMTP khác)
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER, // Email của bạn (cấu hình trong .env)
        pass: process.env.EMAIL_PASS  // Mật khẩu ứng dụng (App Password)
    }
});

export default class userController {

    // 1. Hàm kiểm tra độ mạnh mật khẩu
    static validatePassword(password) {
        const passwordRule = {
            minLength: 8,
            maxLength: 100,
            requiredUpperCase: true,
            requiredLowerCase: true,
            requiredNumber: true,
            requiredSpecial: true
        };

        if (password.length < passwordRule.minLength || password.length > passwordRule.maxLength)
            return false;
        if (passwordRule.requiredUpperCase && !/[A-Z]/.test(password))
            return false;
        if (passwordRule.requiredLowerCase && !/[a-z]/.test(password))
            return false;
        if (passwordRule.requiredNumber && !/[0-9]/.test(password))
            return false;
        if (passwordRule.requiredSpecial && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
            return false;
        }
        return true;
    }

    // Hàm tạo token
    static generateToken(user) {
        return jwt.sign(
            {
                id: user.account_id,
                userId: user.user_id,
                username: user.Username,
                role: user.role
            },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );
    }

    // Đăng ký
    static async register(req, res) {
        try {
            const { username, password, email, phone, fullname } = req.body;

            // Validate dữ liệu đầu vào
            if (!username || !password || !fullname) {
                return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ: username, password, fullname' });
            }

            // 2. Gọi hàm kiểm tra mật khẩu
            if (!userController.validatePassword(password)) {
                return res.status(400).json({
                    success: false,
                    message: 'Mật khẩu yếu! Cần ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.'
                });
            }

            // Kiểm tra username đã tồn tại chưa
            const existingUser = await userModel.findByUsername(username);
            if (existingUser) {
                return res.status(400).json({ success: false, message: 'Username đã tồn tại' });
            }

            // 3. Mã hóa mật khẩu
            const hashedPassword = await hash(password, PASSWORD_HASH_ROUNDS);

            // Tạo user mới (Lưu vào 2 bảng Account và Users)
            const newAccountId = await userModel.create({
                username,
                hashedPassword,
                fullname,
                email,
                phone
            });

            res.status(201).json({
                success: true,
                message: "Đăng ký thành công",
                userId: newAccountId
            });

        } catch (error) {
            console.error(error);
            res.status(500).json({ success: false, message: error.message });
        }
    }

    // Đăng nhập
    static async login(req, res) {
        try {
            const { username, password } = req.body;

            if (!username || !password) {
                return res.status(400).json({ success: false, message: 'Vui lòng nhập username và password' });
            }

            // Tìm user trong DB
            const user = await userModel.findByUsername(username);
            if (!user) {
                return res.status(401).json({ success: false, message: 'Sai thông tin đăng nhập' });
            }

            // 4. So sánh mật khẩu nhập vào với mật khẩu đã mã hóa trong DB
            const isMatch = await compare(password, user.password);
            if (!isMatch) {
                return res.status(401).json({ success: false, message: 'Sai thông tin đăng nhập' });
            }

            // Kiểm tra trạng thái tài khoản
            if (user.status === 0) {
                return res.status(403).json({ success: false, message: 'Tài khoản đã bị khóa' });
            }

            // Tạo token
            const token = userController.generateToken(user);

            // Loại bỏ password khỏi dữ liệu trả về client
            const { password: _, ...userData } = user;

            res.status(200).json({
                success: true,
                message: "Đăng nhập thành công",
                token: token,
                user: userData
            });

        } catch (error) {
            console.error(error);
            res.status(500).json({ success: false, message: "Lỗi Server" });
        }
    }

    // Xem Profile
    static async profile(req, res) {
        try {
            const userId = req.userId;
            const user = await userModel.findById(userId);

            if (!user) {
                return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
            }

            res.status(200).json({
                success: true,
                user: user
            });
        } catch (error) {
            res.status(500).json({ success: false, message: error.message });
        }
    }

    // Cập nhật Profile
    static async updateUserInfo(req, res) {
        try {
            const userId = req.userId;
            const { fullname, email, phone, birthday } = req.body;

            let imageBase64 = null;

            // Xử lý ảnh: Chuyển Buffer sang Base64 string
            if (req.file) {
                if (!req.file.buffer) {
                     throw new Error("Lỗi Server: Không tìm thấy dữ liệu ảnh trong RAM (Kiểm tra lại userRouter)");
                }
                // Tạo chuỗi base64 đầy đủ (vd: data:image/png;base64,RxR...)
                const b64 = Buffer.from(req.file.buffer).toString('base64');
                imageBase64 = `data:${req.file.mimetype};base64,${b64}`;
            }

            if (phone && !/^[0-9]{10}$/.test(phone)) {
                return res.status(400).json({ success: false, message: 'Số điện thoại không hợp lệ (phải là 10 số)' });
            }

            if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
                return res.status(400).json({ success: false, message: 'Email không hợp lệ' });
            }

            const result = await userModel.updateUser(userId, { fullname, email, phone, birthday, image: imageBase64 });

            if (!result.success && result.message) {
                 return res.status(400).json({result});
            }

            const updatedUser = await userModel.findById(userId);

            res.status(200).json({
                success: true,
                message: 'Cập nhật thông tin thành công',
                user: updatedUser
            });

        } catch (error) {
            console.error(error);
            res.status(500).json({ success: false, message: 'Lỗi server: ' + error.message });
        }
    }

    // Hiển thị danh sách địa chỉ
    static async getAddressList(req,res){
        try{
            const userId = req.userId;

            const listAddress = await userModel.getAddressByUserId(userId);

            return res.status(200).json({
                success: true,
                data: listAddress
            });
        }catch(error){
            console.error(error);
            res.status(500).json({success: false, message: 'Lỗi server'});
        }
    }

    // Thêm địa chỉ mới
    static async addAddress(req, res) {
        try {
            const userId = req.userId;
            const { name, street, district, city } = req.body;

            if (!name || !street || !district || !city) {
                return res.status(400).json({
                    success: false,
                    message: "Vui lòng nhập đầy đủ thông tin: Tên, Đường, Quận, Thành phố"
                });
            }

            await userModel.addAddresses({userId: userId, name: name, street: street, district: district, city: city});

            return res.status(200).json({
                success: true,
                message: "Thêm địa chỉ mới thành công"
            });

        } catch (error) {
            if (error.message.includes('đã tồn tại')) {
                return res.status(400).json({
                    success: false,
                    message: "Địa chỉ này đã tồn tại"
                });
            }

            return res.status(500).json({
                success: false,
                message: "Lỗi server khi thêm địa chỉ"
            });
        }
    }

    // Chỉnh chế độ địa chỉ
    static async setDefaultAddress(req, res) {
        try {
            const userId = req.userId;
            const { address_id } = req.body;

            if (!address_id) {
                return res.status(400).json({
                    success: false,
                    message: "Thiếu address_id"
                });
            }

            const isSuccess = await userModel.setDefaultAddress(userId, address_id);

            if (isSuccess) {
                return res.status(200).json({
                    success: true,
                    message: "Đã đặt địa chỉ mặc định"
                });
            } else {
                return res.status(404).json({
                    success: false,
                    message: "Không tìm thấy địa chỉ hoặc địa chỉ không thuộc về bạn"
                });
            }

        } catch (error) {
            console.error("Lỗi set default address:", error);
            return res.status(500).json({
                success: false,
                message: "Lỗi Server"
            });
        }
    }

    //Xóa địa chỉ
    static async deleteAddress(req, res) {
        try {
            const userId = req.userId;
            const { address_id } = req.body;

            if (!address_id) {
                return res.status(400).json({ success: false, message: "Thiếu address_id" });
            }

            await userModel.deleteAddresses(userId, address_id);

            return res.status(200).json({
                success: true,
                message: "Xóa địa chỉ thành công"
            });

        } catch (error) {
            return res.status(400).json({
                success: false,
                message: error.message 
            });
        }
    }
    
    // Forget password
    static async forgetPassword(req, res) {
        try {
            const { username,  } = req.body;
            if (!username || !newPassword) {
                return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ thông tin' });
            }
            const user = await userModel.findByUsername(username);
            if (!user) {
                return res.status(404).json({ success: false, message: 'Người dùng không tồn tại' });
            }
            const hashedPassword = await hash(newPassword, PASSWORD_HASH_ROUNDS);
            await userModel.updatePassword(user.account_id, hashedPassword);
            res.status(200).json({ success: true, message: 'Cập nhật mật khẩu thành công' });
        } catch (error) {
            res.status(500).json({ success: false, message: 'Lỗi server' });
        }
    }

    // Logout
    static async logout(req, res) {
        try {
            res.status(200).json({
                success: true,
                message: 'Đăng xuất thành công'
            });

        } catch (error) {
            res.status(500).json({ success: false, message: 'Lỗi server' });
        }
    }

    static async addFavorites(req,res){
        try {
            const userId = req.userId;
            const { product_id} = req.body;
            if(!userId){
                return res.status(401).send({
                    success: false,
                    message: "Chưa đăng nhập hoặc Token không hợp lệ"
                });
            }
            if(!product_id){
                return res.status(400).send({
                    success: false,
                    message: "Thiếu product_id"
                });
            }
           const result = await userModel.addFavorites(userId,product_id);
           if(result.success == false){
                return res.status(200).json({ success: true, message: 'Bạn đã thích sản phẩm này rồi'});
           }
           return res.status(200).json({ success: true, message: 'Thích sản phẩm thành công'});
        } catch (error) {
            console.error("Lỗi Controller",error),
            res.status(500).json({ success:false, message:"Lỗi server"});
        }
    }  

    static async checkFavorites(req,res){
        try {
            const userId = req.userId;
            const { product_id } = req.query;

            const isFav = await userModel.checkFavorites(userId,product_id);
            return res.status(200).json({
                success: true,
                isFavorited: isFav
            });
        } catch (error) {
            console.error(error);
            return res.status(500).json({ success: false });
        }
    }

    static async removeFavorite(req,res){
        try {
            const UserId = req.userId;
            const { product_id } = req.body

            await userModel.removeFavorites(UserId,product_id);

            return res.status(200).json({
                success: true,
                message: 'Đã xóa yêu thích'
            });

        } catch (error) {
            return res.status(500).json({
                success: false,
                message: 'Lỗi server'
            });
        }
    }

    // Lấy danh sách sản phẩm yêu thích của User
    static async getFavoriteList(req, res) {
        try{
            const userId = req.userId;

            const listFavorites = await userModel.getFavoritesByUserId(userId);

            return  res.status(200).json({
                success: true,
                data: listFavorites
            });
        }catch(error){
            console.error(error);
            res.status(500).json({ success: false, message: 'Lỗi server' });
        }
    }

    // Gửi mã xác thực
    static async sendOtp(req, res) {
        try {
            const { email } = req.body;
            if (!email) {
                return res.status(400).json({ success: false, message: "Vui lòng nhập email" });
            }

            const user = await userModel.findByEmail(email);
            if (!user) {
                return res.status(404).json({ success: false, message: "Email này chưa được đăng ký tài khoản nào." });
            }
            // 1. Tạo mã OTP ngẫu nhiên 6 số
            const otp = Math.floor(100000 + Math.random() * 900000).toString();

            const expiresIn = Date.now() + 5 * 60 * 1000; // 5 phút

            // Lưu OTP vào RAM Hết hạn sau 5 phút
            otpStore.set(email, { code: otp, expiresAt: expiresIn});

            console.log(`OTP cho ${email} là: ${otp}`);

            // Gửi email
            const mailOptions = {
                from: `"App Fast Food" <${process.env.EMAIL_USER}>`,
                to: email,
                subject: 'Mã xác thực đổi mật khẩu - App FastFood',
                html: `
                    <h3>Xin chào ${user.fullname || 'Bạn'},</h3>
                    <p>Bạn vừa yêu cầu đặt lại mật khẩu.</p>
                    <p>Mã xác thực (OTP) của bạn là: <b style="font-size: 20px; color: red;">${otp}</b></p>
                    <p>Mã này sẽ hết hạn sau 5 phút.</p>
                `
            };

            await transporter.sendMail(mailOptions);

            res.status(200).json({ success: true, message: 'Đã gửi mã xác thực vào email' });

        } catch (error) {
            console.error('Lỗi gửi mail:', error);
            res.status(500).json({ success: false, message: 'Lỗi gửi email: ' + error.message });
        }
    }

    // Kiểm tra OTP và Đổi mật khẩu
    static async resetPassword(req, res) {
        try {
            const { email, otp, newPassword } = req.body;

            if (!email || !otp || !newPassword) {
                return res.status(400).json({ success: false, message: 'Vui lòng nhập đầy đủ: email, otp, newPassword' });
            }

            // Kiểm tra OTP trong RAM
            const storedOtpData = otpStore.get(email);

            if (!storedOtpData) {
                return res.status(400).json({ success: false, message: 'Mã xác thực không tồn tại hoặc đã hết hạn' });
            }

            if (storedOtpData.code !== otp) {
                return res.status(400).json({ success: false, message: 'Mã xác thực không chính xác' });
            }

            if (Date.now() > storedOtpData.expireAt) {
                otpStore.delete(email); // Xóa mã hết hạn
                return res.status(400).json({ success: false, message: 'Mã xác thực đã hết hạn' });
            }

            // Validate mật khẩu mới
            if (!userController.validatePassword(newPassword)) {
                return res.status(400).json({
                    success: false,
                    message: 'Mật khẩu yếu! Cần ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.'
                });
            }

            // Lấy thông tin user để lấy account_id
            const user = await userModel.findByEmail(email);
            if (!user) {
                return res.status(404).json({ success: false, message: 'User không tồn tại' });
            }

            // Mã hóa mật khẩu mới và cập nhật vào DB
            const hashedPassword = await hash(newPassword, PASSWORD_HASH_ROUNDS);
            await userModel.updatePassword(user.account_id, hashedPassword);

            // Xóa OTP sau khi dùng xong
            otpStore.delete(email);

            res.status(200).json({ success: true, message: 'Đổi mật khẩu thành công' });

        } catch (error) {
            console.error(error);
            res.status(500).json({ success: false, message: 'Lỗi server' });
        }
    }

    static async addToCart(req,res){
        try {
            const user_id = req.userId;
            const { product_id, quantity , note } = req.body;
            
            const checkItemInCart = await userModel.checkItemInCart(user_id,product_id);

            if(checkItemInCart){
                const addQuantity = checkItemInCart.quantity + quantity;
                
                const updateNote = note !== undefined ? note : checkItemInCart.note;

                await userModel.updateCart(checkItemInCart.cart_id, addQuantity, updateNote);
            }else{
                await userModel.addToCart(user_id,product_id,quantity,note || "");
                return res.status(200).json({
                    success: true,
                    message: 'Thêm Item vào thành công'
                });
            }
        } catch (error) {
            console.error('Add Cart Err', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server'
            });
        }
    }

    static async getCart(req,res){
        try {
            const user_id = req.userId;
            const cartItem = await userModel.getCartByUserId(user_id);

            res.status(200).json({
                success: true,
                data: cartItem
            });          
        } catch (error) {
            console.error("Get Cart Err",error);
            res.status(500).json({
                success: false,
                message: "Lỗi server"
            });
        }
    }

    static async updateCartItem(req,res){
        try {
            const { cart_id, quantity, note } = req.body;
            console.log('Đã nhận: ',cart_id,quantity,note ?? "Không ghi chú");
            await userModel.updateCart(cart_id,quantity,note);
            res.status(200).json({
                success: true,
                message: 'Cập nhật thành công'
            }); 
        } catch (error) {
            console.error("Get Cart Err",error);
            res.status(500).json({
                success: false,
                message: "Lỗi server"
            });
        }
    }

    static async removeCartItem(req,res){
        try {
            const { cart_id } = req.body;
            await userModel.removeCartItem(cart_id);
            return res.status(200).json({
                success: true,
                message: 'Xóa thành công'
            });
        } catch (error) {
             res.status(500).json({
                success: false,
                message: "Lỗi server"
            });
        }
    }

    static async checkAddressById(req,res){
        try {
            
            const userId = req.userId;
            const addressData = await userModel.checkAddressById(userId);
            if(addressData  && addressData.length > 0){
            return res.status(200).json({
                success: true,
                data: addressData
            });
        }
        return res.status(400).json({
            success: false,
            message: 'Lỗi Lỗi không có địa chỉ'
        });
        } catch (error) {
            console.error('Lỗi không check được',error);
            return res.status(500).json({
                success: false,
                message: 'Lỗi server'
            });
        }
    }

    static async priviewOrder(req,res){
        try {
            // Nhận: items (mảng [{productId, quantity}]), promotionId, shippingAddressId
            const { items, promotionId, shippingAddressId } = req.body;

            if (!items || items.length === 0) {
                return res.status(400).json({ message: 'Không có sản phẩm để tính toán' });
            }

            const calculation = await userModel.previewOrder(items, promotionId, shippingAddressId);
            res.status(200).json({ success: true, data: calculation });
        } catch (error) {
            console.error("Preview Order Error:", error);
            res.status(500).json({ message: error.message });
        }
    }

    static async checkout(req,res){
        try {
            const userId = req.userId;
            const { items, shippingAddressId, note, promotionId, paymentMethod, isBuyFromCart } = req.body;

            if (!items || items.length === 0) return res.status(400).json({ message: 'Giỏ hàng trống' });
            if (!shippingAddressId) return res.status(400).json({ message: 'Thiếu địa chỉ giao hàng' });

            const result = await userModel.createOrderTransaction({
                userId,
                items,
                shippingAddressId,
                note,
                promotionId,
                paymentMethod,
                isBuyFromCart // true/false: để biết có xóa giỏ hàng cũ không
            });

            res.status(201).json(result);
        } catch (error) {
            console.error("Checkout Error:", error);
            res.status(500).json({ success: false, message: 'Đặt hàng thất bại: ' + error.message });
        }
    }
}