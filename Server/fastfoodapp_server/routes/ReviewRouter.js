import { Router } from 'express';
import reviewController from '../controller/reviewController.js';
import auth from '../middleware/auth.js';
import ReviewsController from '../controller/reviewController.js';

const reviewRouter = Router();

reviewRouter.post('/reviews/add',auth,ReviewsController.addReview);

export default reviewRouter;