import express from 'express';
import { getAdminOrders, updateOrderStatus, updatePaymentStatus,updateProductStatus,updateProduct } from '../controller/adminController.js';
import getAdminProducts from '../controller/productsController.js';
import auth from '../middleware/auth.js';
const router = express.Router();

router.get('/orders', auth, getAdminOrders);
router.post('/orders/update-status', auth, updateOrderStatus);
router.post('/orders/update-payment-status', auth, updatePaymentStatus); // Route này phải tồn tại
router.get('/products', auth, getAdminProducts);
router.post('/products/update-status', auth, updateProductStatus);
router.post('/products/update', auth, updateProduct);


export default router;

