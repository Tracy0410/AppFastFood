import { Router } from 'express';
import userController from '../controller/userController.js';
import OrderController from '../controller/orderController.js';
import PromotionController from '../controller/promotionsController.js';
import auth from '../middleware/auth.js';
import multer from 'multer';
import { checkAdmin } from '../middleware/auth.js';

const userRouter = Router();

// Cấu hình multer lưu vào bộ nhớ tạm (RAM) thay vì ổ cứng
const storage = multer.memoryStorage(); 

// Bộ lọc chỉ cho phép ảnh
const fileFilter = (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    } else {
        cb(new Error('Chỉ được upload file ảnh!'), false);
    }
};

const upload = multer({ storage: storage, fileFilter: fileFilter });

// Public routes
userRouter.post('/login', userController.login);
userRouter.post('/register', userController.register);
userRouter.delete('/delete/:id', auth, userController.deleteAccount);


// Route nhận kết quả từ VNPay (Method là GET nhé)
userRouter.get('/payment/vnpay_return', userController.vnpayReturn);

// Routes quên mật khẩu
userRouter.post('/send-otp', userController.sendOtp);
userRouter.post('/reset-password', userController.resetPassword);

// Protected routes (Cần Token)
userRouter.get('/profile', auth, userController.profile);
userRouter.post('/profile/update', auth, upload.single('image'), userController.updateUserInfo);
userRouter.post('/profile/change-password', auth, userController.changePassword);
userRouter.post('/logout', auth, userController.logout);

// Routes yêu thích (favorites)
userRouter.post('/favorites/add',auth,userController.addFavorites);
userRouter.get('/favorites/check',auth,userController.checkFavorites);
userRouter.post('/favorites/remove',auth,userController.removeFavorite);
userRouter.get('/favorites/list',auth,userController.getFavoriteList);

// Cart
userRouter.post('/carts/add',auth,userController.addToCart);
userRouter.get('/carts',auth,userController.getCart);
userRouter.put('/carts/update',auth,userController.updateCartItem);
userRouter.delete('/carts/delete',auth,userController.removeCartItem);

//Order
userRouter.post('/orders/preview',auth,userController.priviewOrder);
userRouter.post('/orders/create',auth,userController.checkout);
//Check
userRouter.get('/address/check',auth,userController.checkAddressById);

userRouter.post('/orders/checkout',auth,userController.checkout);

//Address
userRouter.get('/addresses', auth,userController.getAddressList);
userRouter.post('/addresses/add', auth, userController.addAddress);
userRouter.put('/addresses/setup', auth, userController.setDefaultAddress);
userRouter.delete('/addresses/delete', auth, userController.deleteAddress);

userRouter.post('/promotions/check-available', userController.checkAvailablePromotions);
userRouter.get('/promotions/active', userController.getPromotions);

// Lấy danh sách đơn hàng
userRouter.get('/orders/my-orders', auth, userController.getMyOrders);

// Lấy chi tiết đơn hàng
userRouter.get('/orders/detail/:order_id', auth, userController.getOrderDetail);

// Notifications
userRouter.get('/notifications/sync', auth, userController.getNotificationData);
export default userRouter;