import express from 'express';
import multer from 'multer'
import { getAdminOrders, updateOrderStatus, updatePaymentStatus,getAdminProducts,updateProduct } from '../controller/adminController.js';
import auth from '../middleware/auth.js';

const router = express.Router();
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

router.get('/orders', auth, getAdminOrders);
router.post('/orders/update-status', auth, updateOrderStatus);
router.post('/orders/update-payment-status', auth, updatePaymentStatus); // Route này phải tồn tại
router.get('/admin/products', auth, getAdminProducts);
router.post('/admin/products/update', auth, upload.single('image'), updateProduct);

export default router;

