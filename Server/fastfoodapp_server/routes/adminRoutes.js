import express from 'express';
import { getAdminOrders, updateOrderStatus, updatePaymentStatus} from '../controller/adminController.js';
import auth from '../middleware/auth.js';
const router = express.Router();

router.get('/orders', auth, getAdminOrders);
router.post('/orders/update-status', auth, updateOrderStatus);
router.post('/orders/update-payment-status', auth, updatePaymentStatus); // Route này phải tồn tại

export default router;

