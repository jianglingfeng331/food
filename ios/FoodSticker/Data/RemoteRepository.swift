import UIKit

// MARK: - 远程 Dashboard 仓库

final class RemoteDashboardRepository: DashboardRepository {

    func fetchDashboard() async throws -> DashboardData {
        let api = CloudAPI.shared
        // 并行拉取仪表盘 + PK 周数据（含对手信息）
        async let dash = api.dashboard()
        async let pk = api.pkWeek()

        let dashboard = try await dash
        let pkData = try? await pk

        // 按今日日期过滤云端记录，避免昨天的记录被当作今日数据回显
        let todayStr: String = {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            return fmt.string(from: Date())
        }()
        let todayRecords = dashboard.todayRecords.filter { rec in
            // date 字段缺失时也保留（兼容旧后端不返回 date 的情况）
            guard let d = rec.date, !d.isEmpty else { return true }
            return d == todayStr
        }

        // 今日记录汇总
        let foodRecords = todayRecords.filter { $0.type == "food" }
        let exerciseRecords = todayRecords.filter { $0.type == "exercise" }
        let waterRecords = todayRecords.filter { $0.type == "water" }
        let weightRecords = todayRecords.filter { $0.type == "weight" }

        let intake = Int(foodRecords.reduce(0) { $0 + $1.calories })
        let exercise = Int(exerciseRecords.reduce(0) { $0 + $1.calories })
        let exerciseMinutes = Int(exerciseRecords.reduce(0) { $0 + $1.amount })
        // 饮水：取当天最后一条 water 记录的 amount（覆盖式）
        let water = Int(waterRecords.last?.amount ?? 0)
        let latestWeight = weightRecords.last.map { $0.amount }
        let weightTime = weightRecords.last?.time

        // 对手信息来自 pk 接口（不存在则为 nil → 游客态/未绑定）
        let opponent = pkData?.partner

        // PK 比分计算：双方均从 /pk/week 接口取值，保证同源对称
        let hasOpponent = opponent != nil
        // 优先取 pkWeek.me 的每日统计（与对手 partner.dailyStats 同源），兜底用 dashboard
        let myPkStats = pkData?.me.dailyStats
        let myStats = myPkStats ?? dashboard.dailyStats
        let opStats = opponent?.dailyStats
        let myScore: Int? = hasOpponent ? Int(myStats.intake) : nil
        let opScore: Int? = hasOpponent ? Int(opStats?.intake ?? 0) : nil
        // 对手预算为 0 时当作 nil,避免 HomeView 中 max(1, 0)=1 导致进度条满格
        let opGoalRaw: Int? = hasOpponent ? Int(opStats?.target ?? 0) : nil
        let opGoal: Int? = (opGoalRaw ?? 0) > 0 ? opGoalRaw : nil
        // 摄入更低 + 消耗更高 为领先
        let opponentIsLeader: Bool = {
            guard let op = opStats else { return false }
            let myIntake = myStats.intake
            let myBurned = myStats.burned
            return op.intake <= myIntake && op.burned >= myBurned
        }()

        return DashboardData(
            myNickname: dashboard.user.name,
            myAvatarURL: dashboard.user.avatar,
            opponentNickname: opponent?.user.name,
            opponentAvatarURL: opponent?.user.avatar,
            opponentScore: opScore,
            opponentCalorieGoal: opGoal,
            opponentIsLeader: opponentIsLeader,
            hasOpponent: hasOpponent,
            myScore: myScore,
            myWins: nil,
            opponentWins: nil,
            todayCalorieIntake: foodRecords.isEmpty ? nil : intake,
            todayCalorieGoal: dashboard.dailyStats.target > 0 ? Int(dashboard.dailyStats.target) : 0,
            todayExerciseCalories: exerciseRecords.isEmpty ? nil : exercise,
            todayExerciseMinutes: exerciseRecords.isEmpty ? nil : exerciseMinutes,
            todayWaterML: waterRecords.isEmpty ? nil : water,
            waterGoalML: 2000,                                   // 由服务端后续扩展为 user 级别
            latestWeight: latestWeight,
            lastWeightTime: weightTime
        )
    }
}

// MARK: - 远程 Sticker 仓库

final class RemoteStickerRepository: StickerRepository {

    func fetchStickers() async throws -> [StickerItem] {
        let list = try await CloudAPI.shared.stickers()
        return list.map { sticker in
            StickerItem(
                id: sticker.id,
                name: sticker.name,
                imageURL: nil,                          // CloudAPI 返回 b64 而非 URL
                imageData: Data(base64Encoded: sticker.image_b64),
                thumbnailData: nil,
                kcalPer100g: sticker.kcalPer100g,
                proteinG: sticker.proteinG,
                carbG: sticker.carbG,
                fatG: sticker.fatG,
                dietaryFiberG: sticker.dietaryFiberG,
                sodiumMg: sticker.sodiumMg,
                vitaminTips: sticker.vitaminTips,
                typicalPortionG: sticker.typicalPortionG,
                useCount: 0,
                isPreset: false,
                createdAt: Date()
            )
        }
    }

    func uploadSticker(image: UIImage, name: String, nutrition: StickerNutrition) async throws -> StickerItem {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotDecodeContentData)
        }
        try await CloudAPI.shared.addSticker(name: name, imageB64: imageData.base64EncodedString(), nutrition: nutrition)
        // addSticker 目前不返回实体，构造一个本地占位返回
        return StickerItem(
            id: UUID().uuidString,
            name: name,
            imageURL: nil,
            imageData: imageData,
            thumbnailData: nil,
            kcalPer100g: nutrition.kcalPer100g,
            proteinG: nutrition.proteinG,
            carbG: nutrition.carbG,
            fatG: nutrition.fatG,
            dietaryFiberG: nutrition.dietaryFiberG,
            sodiumMg: nutrition.sodiumMg,
            vitaminTips: nutrition.vitaminTips,
            typicalPortionG: nutrition.typicalPortionG,
            useCount: 0,
            isPreset: false,
            createdAt: Date()
        )
    }

    func updateSticker(id: String, name: String?, nutrition: StickerNutrition?) async throws -> StickerItem {
        // TODO: 后端实现 PUT /stickers/:id
        throw RemoteRepoError.notImplemented("PUT /stickers/:id")
    }

    func deleteSticker(id: String) async throws {
        // TODO: 后端实现 DELETE /stickers/:id
        throw RemoteRepoError.notImplemented("DELETE /stickers/:id")
    }

    func markUsed(id: String) async throws {
        // TODO: 后端实现 POST /stickers/:id/use
        // 当前静默忽略，不阻塞 UI
    }
}

// MARK: - 远程 PK 仓库

final class RemotePKRepository: PKRepository {

    // MARK: 绑定

    func sendBindRequest(opponentUID: String) async throws -> PKBindStatus {
        _ = try await CloudAPI.shared.pkBind(targetUID: opponentUID)
        return try await getBindStatus()
    }

    func getBindStatus() async throws -> PKBindStatus {
        // 直接查询云端关系接口（跨设备同步）
        let rel = try await CloudAPI.shared.pkRelation()
        if let p = rel.partner {
            return PKBindStatus(state: .bound(opponent: PKOpponentInfo(
                uid: p.uid,
                nickname: p.nickname,
                avatarURL: nil
            )))
        }
        return PKBindStatus(state: .unbound)
    }

    func unbind() async throws {
        try await CloudAPI.shared.pkUnbind()
    }

    // MARK: 周数据

    func fetchWeeklyData() async throws -> PKWeeklyData {
        let pk = try await CloudAPI.shared.pkWeek()
        return mapPKWeek(pk)
    }

    func submitDailyRecord() async throws {
        // PK 数据由服务端定时任务从记录中汇总，前端无需显式提交
        // 每条记录的写入已在 AppDataStore.addRecord 中通过 CloudAPI.addRecord 完成
    }

    // MARK: 数据映射

    private func mapPKWeek(_ wk: CloudAPI.CkPKWeek) -> PKWeeklyData {
        func mapPerson(_ p: CloudAPI.CkPerson) -> PKWeeklyData.Person {
            let foodRecords = p.todayRecords.filter { $0.type == "food" }
            let exerciseRecords = p.todayRecords.filter { $0.type == "exercise" }
            let waterRecords = p.todayRecords.filter { $0.type == "water" }

            return PKWeeklyData.Person(
                nickname: p.user.name,
                avatarURL: nil,
                dailyIntake: foodRecords.map { Int($0.calories) },
                dailyBurned: exerciseRecords.map { Int($0.calories) },
                exerciseMinutes: exerciseRecords.map { Int($0.amount) },
                weights: [],
                waterML: waterRecords.map { Int($0.amount) },
                waterGoalML: 2000
            )
        }

        let me = mapPerson(wk.me)
        let opponent = wk.partner.map(mapPerson) ?? me

        // 指标计算：当前后端未提供 metrics 字段，用本地空占位。
        // 后续后端扩展 metrics 字段后直接映射。
        let metrics: [PKWeeklyData.Metric] = []

        return PKWeeklyData(
            weekLabel: "本周",
            me: me,
            opponent: opponent,
            metrics: metrics,
            meWinsTotal: 0,
            opponentWinsTotal: 0,
            leaderIsMe: false
        )
    }
}

// MARK: - 错误类型

enum RemoteRepoError: Error, CustomStringConvertible {
    case notImplemented(String)

    var description: String {
        switch self {
        case .notImplemented(let api): return "接口未实现: \(api)"
        }
    }
}
