import express from 'express';
// 1. Import cả Class (Không dùng dấu ngoặc nhọn {})
import PromotionController from '../controller/promotionsController.js'; 

const router = express.Router();


router.get('/', PromotionController.getPromotions);
router.get('/:id/products', PromotionController.getPromotionProducts);

export default router;