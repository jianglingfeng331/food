import Foundation

/// 食物营养识别结果数据模型。
/// 字段严格对齐 DeepSeek 多模态接口返回的 JSON 结构（见 `FoodNutritionService`）。
struct FoodNutritionModel: Codable {
    /// 食物标准名称（中文）
    let foodName: String
    /// 每 100g 热量（千卡）
    let calories: Double
    /// 每 100g 蛋白质（g）
    let protein: Double
    /// 每 100g 脂肪（g）
    let fat: Double
    /// 每 100g 碳水化合物（g）
    let carbohydrate: Double
    /// 每 100g 膳食纤维（g）
    let dietaryFiber: Double
    /// 每 100g 钠（mg）
    let sodium: Double
    /// 核心维生素与矿物质简要说明（≤30 字）
    let vitaminTips: String
}
