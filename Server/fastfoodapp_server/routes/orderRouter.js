import { Router } from 'express';
import OrderController from '../controller/orderController.js';
import auth from '../middleware/auth.js';

const orderRouter = Router();

orderRouter.get('/order', auth, OrderController.getMyOrders);
orderRouter.get('/order/:id', auth, OrderController.getOrderDetail);
orderRouter.post('/order/repay', auth, OrderController.retryPayment);
orderRouter.post('/order/cancel',auth,OrderController.cancelOrder);
orderRouter.get('/order/notification/latest', auth, OrderController.getOrderStatusNotification);

export default orderRouter;