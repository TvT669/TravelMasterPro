//
//  FlightSerachTool.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

class FlightSearchTool: BaseTool {
    private let amadeus: AmadeusService
    
    init() {
        // 初始化 Amadeus 服务
        self.amadeus = AmadeusService()
        
        // ✅ 使用新版本 BaseTool 的构造器
        super.init(
            name: "flight_search",
            description: "搜索航班信息，筛选低价和免费行李额的最优航班",
            parameters: [
                "origin": .string("出发地机场代码或城市名"),
                "destination": .string("目的地机场代码或城市名"),
                "departure_date": .string("出发日期 (YYYY-MM-DD 格式)"),
                "return_date": .string("返程日期 (YYYY-MM-DD 格式)，单程时可选"),
                "adults": .number("成人数量"),
                "travel_class": .string("舱位等级", enumValues: ["ECONOMY", "PREMIUM_ECONOMY", "BUSINESS", "FIRST"]),
                "max_price": .number("最高价格（人民币）"),
                "prefer_free_baggage": .string("是否优先选择免费行李额航班", enumValues: ["true", "false"])
            ],
            requiredParameters: ["origin", "destination", "departure_date"]
        )
    }
    
    // ✅ 重写 executeImpl 而不是 execute
    override func executeImpl(arguments: [String: Any]) async throws -> ToolResult {
        // 使用 BaseTool 提供的参数获取方法
        let origin = try getRequiredString("origin", from: arguments)
        let destination = try getRequiredString("destination", from: arguments)
        let departureDate = try getRequiredString("departure_date", from: arguments)
        let returnDate = getString("return_date", from: arguments)
        
        // 获取其他参数（带默认值）
        let adults = Int(getNumber("adults", from: arguments) ?? 1)
        let travelClass = getString("travel_class", from: arguments) ?? "ECONOMY"
        let maxPrice = getNumber("max_price", from: arguments)
        let preferFreeBaggage = getBoolean("prefer_free_baggage", from: arguments) ?? true
        
        do {
            // 搜索航班
            let searchResult = try await amadeus.searchFlights(
                origin: origin,
                destination: destination,
                departureDate: departureDate,
                returnDate: returnDate,
                adults: adults,
                travelClass: travelClass
            )
            
            // 筛选和排序
            let filteredFlights = filterAndRankFlights(
                flights: searchResult.flights,
                maxPrice: maxPrice,
                preferFreeBaggage: preferFreeBaggage
            )
            
            // 格式化结果
            let formattedResult = formatFlightResults(filteredFlights)
            
            // ✅ 使用 BaseTool 的便利方法
            return successResult(formattedResult, metadata: [
                "search_params": arguments,
                "results_count": filteredFlights.count,
                "currency": "CNY"
            ])
            
        } catch {
            // ✅ 使用 BaseTool 的错误处理方法
            return errorResult("航班搜索失败: \(error.localizedDescription)", metadata: [
                "error_type": String(describing: type(of: error)),
                "search_params": arguments
            ])
        }
    }
    
    // MARK: - 私有方法（保持不变）
    
    private func filterAndRankFlights(
        flights: [FlightOffer],
        maxPrice: Double?,
        preferFreeBaggage: Bool
    ) -> [FlightOffer] {
        var filtered = flights
        
        // 价格筛选
        if let maxPrice = maxPrice {
            filtered = filtered.filter { $0.price <= maxPrice }
        }
        
        // 按优先级排序
        filtered.sort { flight1, flight2 in
            // 1. 优先考虑免费行李额
            if preferFreeBaggage {
                let flight1FreeBaggage = flight1.hasFreeBaggage
                let flight2FreeBaggage = flight2.hasFreeBaggage
                
                if flight1FreeBaggage != flight2FreeBaggage {
                    return flight1FreeBaggage
                }
            }
            
            // 2. 综合评分排序
            let score1 = calculateFlightScore(flight1)
            let score2 = calculateFlightScore(flight2)
            
            return score1 > score2
        }
        
        return Array(filtered.prefix(10))
    }
    
    private func calculateFlightScore(_ flight: FlightOffer) -> Double {
        let priceScore = max(0, 1000 - flight.price) / 1000.0
        let durationScore = max(0, 24 - Double(flight.totalDurationMinutes) / 60.0) / 24.0
        let stopScore = flight.numberOfStops == 0 ? 1.0 : (1.0 / Double(flight.numberOfStops + 1))
        let baggageScore = flight.hasFreeBaggage ? 1.0 : 0.5
        
        return priceScore * 0.4 + durationScore * 0.2 + stopScore * 0.2 + baggageScore * 0.2
    }
    
    private func formatFlightResults(_ flights: [FlightOffer]) -> String {
        guard !flights.isEmpty else {
            return "未找到符合条件的航班"
        }
        
        var result = "🛫 找到 \(flights.count) 个最优航班选择：\n\n"
        
        for (index, flight) in flights.enumerated() {
            let score = calculateFlightScore(flight)
            result += "【选择 \(index + 1)】评分: \(String(format: "%.1f", score * 100))分\n"
            result += "✈️ 航班: \(flight.airlineName) \(flight.flightNumber)\n"
            result += "📍 路线: \(flight.origin) → \(flight.destination)\n"
            result += "⏰ 时间: \(flight.departureTime) → \(flight.arrivalTime)\n"
            result += "💰 价格: ¥\(Int(flight.price))\n"
            result += "⏱️ 时长: \(formatDuration(flight.totalDurationMinutes))\n"
            result += "🔄 转机: \(flight.numberOfStops == 0 ? "直飞 ✅" : "\(flight.numberOfStops)次转机")\n"
            result += "🧳 行李: \(flight.baggageInfo)\n"
            
            if flight.hasFreeBaggage {
                result += "🎁 免费行李额 ✅\n"
            }
            
            result += "\n" + "─".repeated(count: 30) + "\n\n"
        }
        
        return result
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)小时\(mins)分钟"
    }
}

// 字符串扩展
extension String {
    func repeated(count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

// MARK: - Amadeus 服务

class AmadeusService {
    private let apiKey: String
    private let apiSecret: String
    private let environment: String
    private let baseURL: URL
    private let urlSession: URLSession
    private var accessToken: String?
    private var tokenExpiry: Date?
    
    init() {
        // 从 TicketConfig.plist 加载配置
        guard let configPath = Bundle.main.path(forResource: "TicketConfig", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath) as? [String: Any],
              let apiKey = config["AMADEUS_API_KEY"] as? String,
              let apiSecret = config["AMADEUS_API_SECRET"] as? String,
              let environment = config["AMADEUS_ENV"] as? String else {
            fatalError("TicketConfig.plist 配置错误")
        }
        
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.environment = environment
        
        // 设置基础URL
        if environment == "test" {
            self.baseURL = URL(string: "https://test.api.amadeus.com")!
        } else {
            self.baseURL = URL(string: "https://api.amadeus.com")!
        }
        
        let TicketConfig = URLSessionConfiguration.default
        TicketConfig.timeoutIntervalForRequest = 30
        self.urlSession = URLSession(configuration: TicketConfig)
    }
    
    func searchFlights(
        origin: String,
        destination: String,
        departureDate: String,
        returnDate: String? = nil,
        adults: Int = 1,
        travelClass: String = "ECONOMY"
    ) async throws -> FlightSearchResult {
        
        // 确保有有效的访问令牌
        try await ensureValidToken()
        
        // 构建请求参数
        var parameters: [String: String] = [
            "originLocationCode": origin,
            "destinationLocationCode": destination,
            "departureDate": departureDate,
            "adults": String(adults),
            "travelClass": travelClass,
            "max": "50" // 最多返回50个结果
        ]
        
        if let returnDate = returnDate {
            parameters["returnDate"] = returnDate
        }
        
        // 发送请求
        let data = try await sendRequest(
            endpoint: "/v2/shopping/flight-offers",
            method: "GET",
            parameters: parameters
        )
        
        // 解析响应
        let response = try JSONDecoder().decode(AmadeusFlightResponse.self, from: data)
        
        // 转换为内部格式
        let flights = response.data.map { convertToFlightOffer($0) }
        
        return FlightSearchResult(flights: flights)
    }
    
    // MARK: - 私有方法
    
    private func ensureValidToken() async throws {
        if let token = accessToken,
           let expiry = tokenExpiry,
           expiry > Date() {
            return // Token 仍然有效
        }
        
        // 获取新的访问令牌
        try await getAccessToken()
    }
    
    private func getAccessToken() async throws {
        let url = baseURL.appendingPathComponent("/v1/security/oauth2/token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=client_credentials&client_id=\(apiKey)&client_secret=\(apiSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NSError(domain: "AmadeusService", code: -1, userInfo: [NSLocalizedDescriptionKey: "获取访问令牌失败"])
        }
        
        let tokenResponse = try JSONDecoder().decode(AmadeusTokenResponse.self, from: data)
        self.accessToken = tokenResponse.access_token
        self.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 60)) // 提前60秒过期
    }
    
    private func sendRequest(
        endpoint: String,
        method: String = "GET",
        parameters: [String: String]? = nil
    ) async throws -> Data {
        
        var url = baseURL.appendingPathComponent(endpoint)
        
        // 添加查询参数
        if let parameters = parameters, method == "GET" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = parameters.map { URLQueryItem(name: $0, value: $1) }
            url = components.url!
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "AmadeusService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
        
        return data
    }
    
    private func convertToFlightOffer(_ data: AmadeusFlightData) -> FlightOffer {
        let price = Double(data.price.total) ?? 0
        let segments = data.itineraries.flatMap { $0.segments }
        
        let departure = segments.first?.departure
        let arrival = segments.last?.arrival
        
        let totalDuration = calculateTotalDuration(data.itineraries)
        let numberOfStops = max(0, segments.count - 1)
        
        // 检查是否有免费行李额
        let hasFreeBaggage = checkFreeBaggage(data)
        let baggageInfo = formatBaggageInfo(data)
        
        return FlightOffer(
            id: data.id,
            airlineName: getAirlineName(segments.first?.carrierCode ?? ""),
            flightNumber: segments.first?.number ?? "",
            origin: departure?.iataCode ?? "",
            destination: arrival?.iataCode ?? "",
            departureTime: formatDateTime(departure?.at ?? ""),
            arrivalTime: formatDateTime(arrival?.at ?? ""),
            price: price,
            totalDurationMinutes: totalDuration,
            numberOfStops: numberOfStops,
            hasFreeBaggage: hasFreeBaggage,
            baggageInfo: baggageInfo
        )
    }
    
    private func calculateTotalDuration(_ itineraries: [AmadeusItinerary]) -> Int {
        // 简化计算：返回第一个行程的总时长（分钟）
        guard let duration = itineraries.first?.duration else { return 0 }
        return parseDuration(duration)
    }
    
    private func parseDuration(_ duration: String) -> Int {
        // 解析 ISO 8601 duration 格式 (PT2H30M)
        let pattern = "PT(?:(\\d+)H)?(?:(\\d+)M)?"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: duration.utf16.count)
        
        guard let match = regex?.firstMatch(in: duration, options: [], range: range) else {
            return 0
        }
        
        var totalMinutes = 0
        
        // 小时
        if match.range(at: 1).location != NSNotFound,
           let hoursRange = Range(match.range(at: 1), in: duration),
           let hours = Int(duration[hoursRange]) {
            totalMinutes += hours * 60
        }
        
        // 分钟
        if match.range(at: 2).location != NSNotFound,
           let minutesRange = Range(match.range(at: 2), in: duration),
           let minutes = Int(duration[minutesRange]) {
            totalMinutes += minutes
        }
        
        return totalMinutes
    }
    
    private func checkFreeBaggage(_ data: AmadeusFlightData) -> Bool {
        // 检查行李政策，这里简化处理
        // 实际实现需要检查 travelerPricings 中的 fareDetailsBySegment
        return data.travelerPricings.first?.fareDetailsBySegment.first?.includedCheckedBags?.quantity ?? 0 > 0
    }
    
    private func formatBaggageInfo(_ data: AmadeusFlightData) -> String {
        let checkedBags = data.travelerPricings.first?.fareDetailsBySegment.first?.includedCheckedBags?.quantity ?? 0
        
        if checkedBags > 0 {
            return "免费托运行李 \(checkedBags) 件"
        } else {
            return "无免费托运行李"
        }
    }
    
    private func getAirlineName(_ code: String) -> String {
        // 航空公司代码映射，这里只是示例
        let airlines = [
            "CA": "中国国际航空",
            "MU": "中国东方航空",
            "CZ": "中国南方航空",
            "3U": "四川航空",
            "9C": "春秋航空"
        ]
        return airlines[code] ?? code
    }
    
    private func formatDateTime(_ dateTime: String) -> String {
        // 格式化日期时间显示
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateTime) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }
        return dateTime
    }
}

// MARK: - 数据模型

struct FlightSearchResult {
    let flights: [FlightOffer]
}

struct FlightOffer {
    let id: String
    let airlineName: String
    let flightNumber: String
    let origin: String
    let destination: String
    let departureTime: String
    let arrivalTime: String
    let price: Double
    let totalDurationMinutes: Int
    let numberOfStops: Int
    let hasFreeBaggage: Bool
    let baggageInfo: String
}

// Amadeus API 响应模型
struct AmadeusTokenResponse: Codable {
    let access_token: String
    let expires_in: Int
}

struct AmadeusFlightResponse: Codable {
    let data: [AmadeusFlightData]
}

struct AmadeusFlightData: Codable {
    let id: String
    let price: AmadeusPrice
    let itineraries: [AmadeusItinerary]
    let travelerPricings: [AmadeusTravelerPricing]
}

struct AmadeusPrice: Codable {
    let total: String
    let currency: String
}

struct AmadeusItinerary: Codable {
    let duration: String
    let segments: [AmadeusSegment]
}

struct AmadeusSegment: Codable {
    let departure: AmadeusLocation
    let arrival: AmadeusLocation
    let carrierCode: String
    let number: String
}

struct AmadeusLocation: Codable {
    let iataCode: String
    let at: String
}

struct AmadeusTravelerPricing: Codable {
    let fareDetailsBySegment: [AmadeusFareDetails]
}

struct AmadeusFareDetails: Codable {
    let includedCheckedBags: AmadeusBaggage?
}

struct AmadeusBaggage: Codable {
    let quantity: Int
}
