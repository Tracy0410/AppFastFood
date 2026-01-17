import express from 'express';
import ProductController from '../controller/productsController.js';
const router = express.Router();

// --- CÁC ROUTE CŨ ---
router.get('/products', ProductController.getAllProducts);
router.get('/products/filter', ProductController.filterProducts);
router.get('/products/:id', ProductController.getProductDetail);
export default router;