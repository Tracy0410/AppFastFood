import { Router } from 'express';
import OrderController from '../controller/orderController.js';
import auth from '../middleware/auth.js';
const orderRouter = Router();
orderRouter.get('/order', auth, OrderController.getMyOrders);

orderRouter.get('/order/:id', auth, OrderController.getOrderDetail);

orderRouter.post('/order/repay', auth, OrderController.retryPayment);

export default orderRouter;