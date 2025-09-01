//
//  HotelSearchTool.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

/// 酒店搜索工具 - 提供全面的酒店搜索和筛选功能
class HotelSearchTool: BaseTool {
    
    init() {
        super.init(
            name: "hotel_search",
            description: "搜索酒店信息，支持位置、价格、设施、评分等多维度筛选",
            parameters: [
                "city": ParameterDefinition(
                    type: "string",
                    description: "目标城市名称",
                    enumValues: nil
                ),
                "checkin_date": ParameterDefinition(
                    type: "string",
                    description: "入住日期 (YYYY-MM-DD 格式)",
                    enumValues: nil
                ),
                "checkout_date": ParameterDefinition(
                    type: "string",
                    description: "退房日期 (YYYY-MM-DD 格式)",
                    enumValues: nil
                ),
                "location": ParameterDefinition(
                    type: "string",
                    description: "具体位置（地址、地标、地铁站等）",
                    enumValues: nil
                ),
                "min_price": ParameterDefinition(
                    type: "number",
                    description: "最低价格（人民币/晚）",
                    enumValues: nil
                ),
                "max_price": ParameterDefinition(
                    type: "number",
                    description: "最高价格（人民币/晚）",
                    enumValues: nil
                ),
                "star_rating": ParameterDefinition.string(
                    "酒店星级",
                    enumValues: ["1", "2", "3", "4", "5", "any"]
                ),
                "amenities": ParameterDefinition(
                    type: "string",
                    description: "必需设施，逗号分隔（wifi,pool,gym,breakfast,parking）",
                    enumValues: nil
                ),
                "hotel_type": ParameterDefinition.string(
                    "酒店类型",
                    enumValues: ["hotel", "resort", "apartment", "hostel", "guesthouse", "any"]
                ),
                "near_metro": ParameterDefinition.string(
                    "是否靠近地铁",
                    enumValues: ["true", "false"]
                ),
                "max_walk_minutes": ParameterDefinition(
                    type: "number",
                    description: "到地铁站最大步行分钟数",
                    enumValues: nil
                ),
                "guests": ParameterDefinition(
                    type: "number",
                    description: "入住人数",
                    enumValues: nil
                ),
                "rooms": ParameterDefinition(
                    type: "number",
                    description: "房间数量",
                    enumValues: nil
                ),
                "sort_by": ParameterDefinition.string(
                    "排序方式",
                    enumValues: ["price", "rating", "distance", "popularity"]
                ),
                "max_results": ParameterDefinition(
                    type: "number",
                    description: "最大返回结果数",
                    enumValues: nil
                )
            ],
            requiredParameters: ["city", "checkin_date", "checkout_date"]
        )
    }
    
    override func executeImpl(arguments: [String: Any]) async throws -> ToolResult {
        // 获取基础参数
        let city = try getRequiredString("city", from: arguments)
        let location = getString("location", from: arguments)
        let checkinDate = try getRequiredString("checkin_date", from: arguments)
        let checkoutDate = try getRequiredString("checkout_date", from: arguments)
        let guests = Int(getNumber("guests", from: arguments) ?? 2)
        let rooms = Int(getNumber("rooms", from: arguments) ?? 1)
        
        // 筛选条件
        let minPrice = getNumber("min_price", from: arguments)
        let maxPrice = getNumber("max_price", from: arguments)
        let starRating = getString("star_rating", from: arguments)
        let amenities = getString("amenities", from: arguments)?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        let hotelType = getString("hotel_type", from: arguments) ?? "any"
        let nearMetro = getBoolean("near_metro", from: arguments) ?? false
        let maxWalkMinutes = Int(getNumber("max_walk_minutes", from: arguments) ?? 10)
        let sortBy = getString("sort_by", from: arguments) ?? "rating"
        let maxResults = Int(getNumber("max_results", from: arguments) ?? 10)
        
        do {
            // 验证日期
            try validateDates(checkin: checkinDate, checkout: checkoutDate)
            
            // 创建搜索服务
            let searchService = HotelSearchService()
            
            // 执行搜索
            let searchResults = try await searchService.searchHotels(
                city: city,
                location: location,
                checkinDate: checkinDate,
                checkoutDate: checkoutDate,
                guests: guests,
                rooms: rooms
            )
            
            // 应用筛选条件
            let filteredResults = try await applyFilters(
                hotels: searchResults,
                minPrice: minPrice,
                maxPrice: maxPrice,
                starRating: starRating,
                amenities: amenities,
                hotelType: hotelType,
                nearMetro: nearMetro,
                maxWalkMinutes: maxWalkMinutes,
                city: city
            )
            
            // 排序和限制结果
            let sortedResults = sortHotels(filteredResults, by: sortBy)
            let finalResults = Array(sortedResults.prefix(maxResults))
            
            // 格式化结果
            let formattedResult = formatHotelResults(
                hotels: finalResults,
                city: city,
                checkinDate: checkinDate,
                checkoutDate: checkoutDate,
                searchCriteria: arguments
            )
            
            return successResult(formattedResult, metadata: [
                "total_found": searchResults.count,
                "after_filtering": filteredResults.count,
                "returned": finalResults.count,
                "search_location": location ?? city,
                "price_range": [minPrice, maxPrice].compactMap { $0 }
            ])
            
        } catch {
            return errorResult("酒店搜索失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 私有方法
    
    private func validateDates(checkin: String, checkout: String) throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let checkinDate = formatter.date(from: checkin),
              let checkoutDate = formatter.date(from: checkout) else {
            throw ToolError.executionFailed("日期格式错误，请使用 YYYY-MM-DD 格式")
        }
        
        guard checkinDate < checkoutDate else {
            throw ToolError.executionFailed("退房日期必须晚于入住日期")
        }
        
        guard checkinDate >= Date().addingTimeInterval(-24*3600) else {
            throw ToolError.executionFailed("入住日期不能是过去的日期")
        }
    }
    
    private func applyFilters(
        hotels: [HotelInfo],
        minPrice: Double?,
        maxPrice: Double?,
        starRating: String?,
        amenities: [String],
        hotelType: String,
        nearMetro: Bool,
        maxWalkMinutes: Int,
        city: String
    ) async throws -> [HotelInfo] {
        
        var filtered = hotels
        
        // 价格筛选
        if let minPrice = minPrice {
            filtered = filtered.filter { $0.pricePerNight >= minPrice }
        }
        if let maxPrice = maxPrice {
            filtered = filtered.filter { $0.pricePerNight <= maxPrice }
        }
        
        // 星级筛选
        if let starRating = starRating, starRating != "any", let rating = Int(starRating) {
            filtered = filtered.filter { $0.starRating >= rating }
        }
        
        // 酒店类型筛选
        if hotelType != "any" {
            filtered = filtered.filter { $0.type.lowercased() == hotelType.lowercased() }
        }
        
        // 设施筛选
        if !amenities.isEmpty {
            filtered = filtered.filter { hotel in
                amenities.allSatisfy { amenity in
                    hotel.amenities.contains { $0.lowercased().contains(amenity.lowercased()) }
                }
            }
        }
        // 地铁站筛选 
        if nearMetro {
            let config = try MapConfiguration.load()
            let amapService = AMapService(config: config)
            
            var metroFilteredHotels: [HotelInfo] = []
            for hotel in filtered {
                do {
                    let isNearMetro = try await isHotelNearMetro(
                        hotel: hotel,
                        city: city,
                        maxWalkMinutes: maxWalkMinutes,
                        amapService: amapService
                    )
                    if isNearMetro {
                        metroFilteredHotels.append(hotel)
                    }
                } catch {
                    // 如果检查失败，保留酒店（避免因网络问题丢失结果）
                    metroFilteredHotels.append(hotel)
                }
            }
            filtered = metroFilteredHotels
        }
        
        
        return filtered
    }
    
    private func isHotelNearMetro(
        hotel: HotelInfo,
        city: String,
        maxWalkMinutes: Int,
        amapService: AMapService
    ) async throws -> Bool {
        // 搜索酒店附近的地铁站
        let location = hotel.location
        let components = location.split(separator: ",")
        guard components.count == 2,
              let lng = Double(components[0]),
              let lat = Double(components[1]) else {
            return false
        }
        
        // 搜索附近的地铁站
        let nearbyStations = try await amapService.searchNearbyMetroStations(
            lng: lng,
            lat: lat,
            radius: maxWalkMinutes * 100 // 粗略估算：100米/分钟
        )
        
        // 检查是否有地铁站在步行范围内
        for station in nearbyStations {
            do {
                let walkingTime = try await amapService.walkingSecs(
                    origin: (lng, lat),
                    dest: station.location
                )
                let walkingMinutes = Int(ceil(Double(walkingTime) / 60.0))
                if walkingMinutes <= maxWalkMinutes {
                    return true
                }
            } catch {
                continue
            }
        }
        
        return false
    }
    
    private func sortHotels(_ hotels: [HotelInfo], by sortBy: String) -> [HotelInfo] {
        switch sortBy {
        case "price":
            return hotels.sorted { $0.pricePerNight < $1.pricePerNight }
        case "rating":
            return hotels.sorted { $0.rating > $1.rating }
        case "distance":
            return hotels.sorted { ($0.distanceFromCenter ?? Double.greatestFiniteMagnitude) < ($1.distanceFromCenter ?? Double.greatestFiniteMagnitude) }
        case "popularity":
            return hotels.sorted { $0.reviewCount > $1.reviewCount }
        default:
            return hotels.sorted { $0.rating > $1.rating }
        }
    }
    
    private func formatHotelResults(
        hotels: [HotelInfo],
        city: String,
        checkinDate: String,
        checkoutDate: String,
        searchCriteria: [String: Any]
    ) -> String {
        guard !hotels.isEmpty else {
            return "未找到符合条件的酒店"
        }
        
        var result = """
        🏨 【\(city) 酒店搜索结果】
        📅 入住：\(checkinDate) → 退房：\(checkoutDate)
        🔍 找到 \(hotels.count) 家符合条件的酒店
        
        """
        
        for (index, hotel) in hotels.enumerated() {
            result += """
            【酒店 \(index + 1)】⭐️ \(hotel.starRating)星
            🏨 \(hotel.name)
            📍 \(hotel.address)
            💰 ¥\(Int(hotel.pricePerNight))/晚
            ⭐️ \(String(format: "%.1f", hotel.rating))分 (\(hotel.reviewCount)条评价)
            🚇 \(hotel.nearestMetro ?? "距离市中心较远")
            🎯 设施：\(hotel.amenities.prefix(3).joined(separator: "、"))
            
            """
        }
        
        return result
    }
}

// MARK: - 数据模型

/// 酒店信息
struct HotelInfo {
    let id: String
    let name: String
    let address: String
    let location: String // "lng,lat"
    let starRating: Int
    let rating: Double
    let reviewCount: Int
    let pricePerNight: Double
    let type: String
    let amenities: [String]
    let imageUrls: [String]
    let nearestMetro: String?
    let distanceFromCenter: Double?
}

/// 酒店搜索服务
class HotelSearchService {
    
    func searchHotels(
        city: String,
        location: String?,
        checkinDate: String,
        checkoutDate: String,
        guests: Int,
        rooms: Int
    ) async throws -> [HotelInfo] {
        // 这里集成真实的酒店搜索API
        // 例如：Booking.com API, Expedia API, 或高德酒店POI搜索
        
        let config = try MapConfiguration.load()
        let amapService = AMapService(config: config)
        
        // 先获取搜索位置的坐标
        let (lng, lat) = try await getSearchCoordinates(
            city: city,
            location: location,
            amapService: amapService
        )
        
        // 搜索周边酒店POI
        let hotelPOIs = try await amapService.searchHotelsAround(
            lng: lng,
            lat: lat,
            radius: 5000, // 5公里范围
            limit: 50
        )
        
        // 转换为 HotelInfo 格式
        return hotelPOIs.map { poi in
            HotelInfo(
                id: poi.id ?? UUID().uuidString,
                name: poi.name,
                address: poi.address ?? "",
                location: poi.location,
                starRating: extractStarRating(from: poi.name),
                rating: Double.random(in: 3.5...4.8), // 模拟评分
                reviewCount: Int.random(in: 50...2000), // 模拟评价数
                pricePerNight: generatePrice(starRating: extractStarRating(from: poi.name)),
                type: extractHotelType(from: poi.name),
                amenities: generateAmenities(),
                imageUrls: [],
                nearestMetro: nil,
                distanceFromCenter: Double(poi.distance ?? "0")
            )
        }
    }
    
    private func getSearchCoordinates(
        city: String,
        location: String?,
        amapService: AMapService
    ) async throws -> (Double, Double) {
        if let location = location {
            // 如果指定了具体位置，优先搜索具体位置
            return try await amapService.geocode(address: "\(city)\(location)")
        } else {
            // 否则搜索城市中心
            return try await amapService.geocode(address: city)
        }
    }
    
    private func extractStarRating(from name: String) -> Int {
        // 从酒店名称中提取星级信息的简单逻辑
        if name.contains("五星") || name.contains("5星") { return 5 }
        if name.contains("四星") || name.contains("4星") { return 4 }
        if name.contains("三星") || name.contains("3星") { return 3 }
        if name.contains("豪华") || name.contains("国际") { return 4 }
        if name.contains("商务") || name.contains("酒店") { return 3 }
        if name.contains("快捷") || name.contains("经济") { return 2 }
        return 3 // 默认3星
    }
    
    private func extractHotelType(from name: String) -> String {
        if name.contains("度假") || name.contains("Resort") { return "resort" }
        if name.contains("公寓") || name.contains("Apartment") { return "apartment" }
        if name.contains("青旅") || name.contains("Hostel") { return "hostel" }
        if name.contains("民宿") || name.contains("Guest") { return "guesthouse" }
        return "hotel"
    }
    
    private func generatePrice(starRating: Int) -> Double {
        switch starRating {
        case 1: return Double.random(in: 80...150)
        case 2: return Double.random(in: 120...250)
        case 3: return Double.random(in: 200...400)
        case 4: return Double.random(in: 350...800)
        case 5: return Double.random(in: 600...2000)
        default: return Double.random(in: 200...400)
        }
    }
    
    private func generateAmenities() -> [String] {
        let allAmenities = ["免费WiFi", "停车场", "游泳池", "健身房", "早餐", "空调", "电视", "冰箱", "洗衣服务", "24小时前台"]
        return Array(allAmenities.shuffled().prefix(Int.random(in: 3...6)))
    }
}



