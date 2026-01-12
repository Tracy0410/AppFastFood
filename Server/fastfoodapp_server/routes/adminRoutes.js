import express from 'express';
import { getAdminOrders, updateOrderStatus } from '../controller/adminController.js';
import auth from '../middleware/auth.js';
const router = express.Router();

router.get('/orders', auth, getAdminOrders);
router.post('/orders/update-status', auth, updateOrderStatus);

export default router;

