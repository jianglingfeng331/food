import Foundation
import SQLite3

struct FoodInfo {
    let nameCN: String
    let kcal100g: Double      // 千卡/100g
    let proteinG: Double      // 克/100g
    let carbG: Double
    let fatG: Double
    let typicalG: Double      // 典型单份克重
    var fromCloud = false
    var portionG: Double? = nil   // 云端估算分量（端侧为nil）
}

/// 本地营养库（只读SQLite，随Bundle打包，首启拷贝到Documents）
final class NutritionDB {
    static let shared = NutritionDB()
    private var db: OpaquePointer?

    private init() {
        let dst = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("nutrition.db")
        if !FileManager.default.fileExists(atPath: dst.path),
           let src = Bundle.main.url(forResource: "nutrition", withExtension: "db") {
            try? FileManager.default.copyItem(at: src, to: dst)
        }
        sqlite3_open_v2(dst.path, &db, SQLITE_OPEN_READONLY, nil)
    }

    /// 按分类模型 class_id 精确查询
    func query(classId: Int) -> FoodInfo? {
        fetch(sql: """
            SELECT name_cn, kcal_100g, protein_g, carb_g, fat_g, typical_g
            FROM food WHERE class_id = ?
            """) { sqlite3_bind_int($0, 1, Int32(classId)) }
    }

    /// 用户手动修正：名称/别名模糊搜索
    func search(name: String) -> FoodInfo? {
        fetch(sql: """
            SELECT f.name_cn, f.kcal_100g, f.protein_g, f.carb_g, f.fat_g, f.typical_g
            FROM food f
            LEFT JOIN food_alias a ON a.food_id = f.id
            WHERE f.name_cn LIKE ? OR a.alias LIKE ? LIMIT 1
            """) {
            let p = "%\(name)%"
            sqlite3_bind_text($0, 1, p, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_text($0, 2, p, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }
    }

    private func fetch(sql: String, bind: (OpaquePointer) -> Void) -> FoodInfo? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        bind(stmt!)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return FoodInfo(
            nameCN: String(cString: sqlite3_column_text(stmt, 0)),
            kcal100g: sqlite3_column_double(stmt, 1),
            proteinG: sqlite3_column_double(stmt, 2),
            carbG: sqlite3_column_double(stmt, 3),
            fatG: sqlite3_column_double(stmt, 4),
            typicalG: sqlite3_column_double(stmt, 5))
    }
}
