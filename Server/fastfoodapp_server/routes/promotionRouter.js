import express from 'express';
// 1. Import cả Class (Không dùng dấu ngoặc nhọn {})
import PromotionController from '../controller/promotionsController.js'; 

const router = express.Router();


router.get('/', PromotionController.getPromotions);

export default router;