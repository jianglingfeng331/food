package com.foodsticker.nutrition

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File

data class FoodInfo(
    val nameCn: String,
    val kcal100g: Double,     // 千卡/100g
    val proteinG: Double,     // 克/100g
    val carbG: Double,
    val fatG: Double,
    val typicalG: Double,
    val fromCloud: Boolean = false,
    val portionG: Double? = null,   // 云端估算分量
)

/** 本地营养库（assets预打包只读SQLite，首启拷贝） */
class NutritionDb(context: Context) {
    private val db: SQLiteDatabase

    init {
        val file = File(context.filesDir, "nutrition.db")
        if (!file.exists()) {
            context.assets.open("nutrition.db").use { input ->
                file.outputStream().use { input.copyTo(it) }
            }
        }
        db = SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY)
    }

    fun queryByClassId(classId: Int): FoodInfo? =
        db.rawQuery(
            """SELECT name_cn, kcal_100g, protein_g, carb_g, fat_g, typical_g
               FROM food WHERE class_id = ?""", arrayOf(classId.toString())
        ).use { c ->
            if (!c.moveToFirst()) return null
            FoodInfo(c.getString(0), c.getDouble(1), c.getDouble(2),
                     c.getDouble(3), c.getDouble(4), c.getDouble(5))
        }

    /** 用户手动修正：名称/别名模糊搜索 */
    fun searchByName(name: String): FoodInfo? =
        db.rawQuery(
            """SELECT f.name_cn, f.kcal_100g, f.protein_g, f.carb_g, f.fat_g, f.typical_g
               FROM food f LEFT JOIN food_alias a ON a.food_id = f.id
               WHERE f.name_cn LIKE ? OR a.alias LIKE ? LIMIT 1""",
            arrayOf("%$name%", "%$name%")
        ).use { c ->
            if (!c.moveToFirst()) return null
            FoodInfo(c.getString(0), c.getDouble(1), c.getDouble(2),
                     c.getDouble(3), c.getDouble(4), c.getDouble(5))
        }
}
