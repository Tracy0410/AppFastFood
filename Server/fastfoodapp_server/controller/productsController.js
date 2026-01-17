import productsModel from '../models/productsModel.js';

class ProductController{
    static async getAllProducts(req,res){
        try{
            const products = await productsModel.getAll();
        
            return res.status(200).json({
                success: true,
                message:'get success products list',
                data: products
            });
        }catch(error){
            console.error(error);
            return res.status(500).json({
                success: false,
                message: 'Error server when get products'
            });
        }
    }

    static async getProductDetail(req,res){
        try{
            const { id } = req.params;
            const product = await productsModel.getById(id);

            if(!product){
                return res.status(401).json({
                    success: false,
                    message: 'Not found product'
                });
            }

            const reviews = await productsModel.getReviewProductId(id);

            product.reviews = reviews;

            return res.status(200).json({
                success: true,
                data: product
            });
        }catch(error){
            return res.status(500).json({
                success: false,
                message: 'Error server'
            });
        }
    }

    static async filterProducts(req, res) {
        try {
            let { categoryId, minPrice, maxPrice, rating, keyword } = req.query;

            // 1. ÉP KIỂU DỮ LIỆU (QUAN TRỌNG)
            // Chuyển chuỗi "150000" thành số 150000 để SQL so sánh đúng
            const minPriceNum = minPrice ? parseFloat(minPrice) : 0;
            const maxPriceNum = maxPrice ? parseFloat(maxPrice) : undefined;
            const ratingNum = rating ? parseInt(rating) : 0;

            const products = await productsModel.filter({
                categoryId,
                minPrice: minPriceNum,
                maxPrice: maxPriceNum,
                rating: ratingNum,
                keyword
            });

            return res.status(200).json({
                success: true,
                message: 'Filter success',
                data: products
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: 'Error server when filtering'
            });
        }
    }
        static async getAdminProducts(req,res){
        try{
            const products = await productsModel.getAlladmin();
        
            return res.status(200).json({
                success: true,
                message:'get success products list',
                data: products
            });
        }catch(error){
            console.error(error);
            return res.status(500).json({
                success: false,
                message: 'Error server when get products'
            });
        }
    }
}

export default ProductController;