//
//  AMapService.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/31.
//

import Foundation

/// 高德地图服务 - 提供地理编码、POI搜索、路径规划等功能
class AMapService {
    private let config: MapConfiguration
    private let session = URLSession.shared
    
    // 高德地图API基础URL
    private let baseURL = "https://restapi.amap.com/v3"
    
    init(config: MapConfiguration) {
        self.config = config
    }
    
    // MARK: - 地理编码
    
    /// 地址转坐标
    func geocode(address: String) async throws -> (Double, Double) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "\(baseURL)/geocode/geo?key=\(config.amapWebKey)&address=\(encodedAddress)"
        
        guard let url = URL(string: urlString) else {
            throw AMapError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AMapError.networkError
        }
        
        let result = try JSONDecoder().decode(GeocodeResponse.self, from: data)
        
        guard result.status == "1",
              let geocode = result.geocodes.first,
              let location = geocode.location else {
            throw AMapError.geocodeFailed
        }
        
        let coordinates = location.split(separator: ",")
        guard coordinates.count == 2,
              let lng = Double(coordinates[0]),
              let lat = Double(coordinates[1]) else {
            throw AMapError.invalidCoordinates
        }
        
        return (lng, lat)
    }
    
    // MARK: - POI搜索
    
    /// 搜索周边酒店
    func searchHotelsAround(
        lng: Double,
        lat: Double,
        radius: Int = 5000,
        limit: Int = 50
    ) async throws -> [POIInfo] {
        let urlString = "\(baseURL)/place/around?key=\(config.amapWebKey)&location=\(lng),\(lat)&keywords=酒店&types=100301&radius=\(radius)&offset=\(limit)&page=1&extensions=all"
        
        guard let url = URL(string: urlString) else {
            throw AMapError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AMapError.networkError
        }
        
        let result = try JSONDecoder().decode(POISearchResponse.self, from: data)
        
        guard result.status == "1" else {
            throw AMapError.searchFailed
        }
        
        return result.pois
    }
    
    /// 搜索周边地铁站
    func searchNearbyMetroStations(
        lng: Double,
        lat: Double,
        radius: Int
    ) async throws -> [(name: String, location: (Double, Double))] {
        let urlString = "\(baseURL)/place/around?key=\(config.amapWebKey)&location=\(lng),\(lat)&keywords=地铁站&types=150500&radius=\(radius)&offset=20&page=1"
        
        guard let url = URL(string: urlString) else {
            throw AMapError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AMapError.networkError
        }
        
        let result = try JSONDecoder().decode(POISearchResponse.self, from: data)
        
        guard result.status == "1" else {
            return []
        }
        
        return result.pois.compactMap { poi in
            let coordinates = poi.location.split(separator: ",")
            guard coordinates.count == 2,
                  let lng = Double(coordinates[0]),
                  let lat = Double(coordinates[1]) else {
                return nil
            }
            return (name: poi.name, location: (lng, lat))
        }
    }
    
    /// 搜索航班相关POI（机场、航空公司等）
    func searchFlightPOIs(
        city: String,
        keywords: String = "机场"
    ) async throws -> [POIInfo] {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let encodedKeywords = keywords.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keywords
        
        let urlString = "\(baseURL)/place/text?key=\(config.amapWebKey)&keywords=\(encodedKeywords)&city=\(encodedCity)&types=150101&offset=20&page=1&extensions=all"
        
        guard let url = URL(string: urlString) else {
            throw AMapError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AMapError.networkError
        }
        
        let result = try JSONDecoder().decode(POISearchResponse.self, from: data)
        
        guard result.status == "1" else {
            throw AMapError.searchFailed
        }
        
        return result.pois
    }
    
    // MARK: - 路径规划
    
    /// 计算步行时间（秒）
    func walkingSecs(
        origin: (Double, Double),
        dest: (Double, Double)
    ) async throws -> Int {
        let urlString = "\(baseURL)/direction/walking?key=\(config.amapWebKey)&origin=\(origin.0),\(origin.1)&destination=\(dest.0),\(dest.1)"
        
        guard let url = URL(string: urlString) else {
            throw AMapError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AMapError.networkError
        }
        
        let result = try JSONDecoder().decode(WalkingResponse.self, from: data)
        
        guard result.status == "1",
              let route = result.route,
              let path = route.paths.first else {
            throw AMapError.routePlanningFailed
        }
        
        return Int(path.duration) ?? 0
    }
    
    /// 计算驾车路径
    func drivingRoute(
        origin: (Double, Double),
        dest: (Double, Double)
    ) async throws -> RouteInfo {
        let urlString = "\(baseURL)/direction/driving?key=\(config.amapWebKey)&origin=\(origin.0),\(origin.1)&destination=\(dest.0),\(dest.1)&extensions=all"
        
        guard let url = URL(string: urlString) else {
            throw AMapError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AMapError.networkError
        }
        
        let result = try JSONDecoder().decode(DrivingResponse.self, from: data)
        
        guard result.status == "1",
              let route = result.route,
              let path = route.paths.first else {
            throw AMapError.routePlanningFailed
        }
        
        return RouteInfo(
            distance: Int(path.distance) ?? 0,
            duration: Int(path.duration) ?? 0,
            strategy: path.strategy ?? "",
            tolls: Int(path.tolls!) ?? 0,
            steps: path.steps.map { step in
                RouteStep(
                    instruction: step.instruction,
                    distance: Int(step.distance) ?? 0,
                    duration: Int(step.duration) ?? 0,
                    polyline: step.polyline
                )
            }
        )
    }
}

// MARK: - 数据模型

/// POI信息
struct POIInfo: Codable {
    let id: String?
    let name: String
    let type: String?
    let typecode: String?
    let address: String?
    let location: String
    let tel: String?
    let distance: String?
    let bizExt: BizExt?
    
    struct BizExt: Codable {
        let rating: String?
        let cost: String?
    }
}

/// 地理编码响应
struct GeocodeResponse: Codable {
    let status: String
    let info: String
    let infocode: String
    let count: String
    let geocodes: [Geocode]
    
    struct Geocode: Codable {
        let formatted_address: String?
        let country: String?
        let province: String?
        let city: String?
        let citycode: String?
        let district: String?
        let township: String?
        let neighborhood: String?
        let building: String?
        let adcode: String?
        let street: String?
        let number: String?
        let location: String?
        let level: String?
    }
}

/// POI搜索响应
struct POISearchResponse: Codable {
    let status: String
    let info: String
    let infocode: String
    let count: String
    let suggestion: Suggestion?
    let pois: [POIInfo]
    
    struct Suggestion: Codable {
        let keywords: [String]?
        let cities: [String]?
    }
}

/// 步行路径响应
struct WalkingResponse: Codable {
    let status: String
    let info: String
    let infocode: String
    let count: String
    let route: WalkingRoute?
    
    struct WalkingRoute: Codable {
        let origin: String
        let destination: String
        let distance: String
        let paths: [WalkingPath]
        
        struct WalkingPath: Codable {
            let distance: String
            let duration: String
            let steps: [WalkingStep]
            
            struct WalkingStep: Codable {
                let instruction: String
                let orientation: String?
                let distance: String
                let duration: String
                let polyline: String
            }
        }
    }
}

/// 驾车路径响应
struct DrivingResponse: Codable {
    let status: String
    let info: String
    let infocode: String
    let count: String
    let route: DrivingRoute?
    
    struct DrivingRoute: Codable {
        let origin: String
        let destination: String
        let distance: String
        let paths: [DrivingPath]
        
        struct DrivingPath: Codable {
            let distance: String
            let duration: String
            let strategy: String?
            let tolls: String?
            let tollDistance: String?
            let steps: [DrivingStep]
            
            struct DrivingStep: Codable {
                let instruction: String
                let orientation: String?
                let distance: String
                let duration: String
                let polyline: String
                let action: String?
                let assistantAction: String?
            }
        }
    }
}

/// 路径信息
struct RouteInfo {
    let distance: Int      // 距离（米）
    let duration: Int      // 时间（秒）
    let strategy: String   // 策略
    let tolls: Int         // 过路费（分）
    let steps: [RouteStep] // 路径步骤
}

/// 路径步骤
struct RouteStep {
    let instruction: String // 导航指令
    let distance: Int       // 距离（米）
    let duration: Int       // 时间（秒）
    let polyline: String    // 路径坐标串
}

/// 地图配置
struct MapConfiguration: Codable {
    let amapWebKey: String
    let lang: String
    let defaultCity: String
    
    static func load() throws -> MapConfiguration {
        guard let path = Bundle.main.path(forResource: "MapConfig", ofType: "plist"),
              let data = FileManager.default.contents(atPath: path) else {
            throw AMapError.configurationError
        }
        
        let decoder = PropertyListDecoder()
        return try decoder.decode(MapConfiguration.self, from: data)
    }
}

/// 高德地图错误类型
enum AMapError: Error, LocalizedError {
    case invalidURL
    case networkError
    case geocodeFailed
    case searchFailed
    case routePlanningFailed
    case invalidCoordinates
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .networkError:
            return "网络请求失败"
        case .geocodeFailed:
            return "地理编码失败"
        case .searchFailed:
            return "POI搜索失败"
        case .routePlanningFailed:
            return "路径规划失败"
        case .invalidCoordinates:
            return "无效的坐标"
        case .configurationError:
            return "配置文件加载失败"
        }
    }
}
