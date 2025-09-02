//
//  SearchFormView.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/9/2.
//

import SwiftUI

/// 搜索表单界面
struct SearchFormView: View {
    @State private var selectedSearchType: SearchType = .hotel
    @State private var searchResults: [SearchResult] = []
    @State private var isLoading = false
    
    enum SearchType: String, CaseIterable {
        case hotel = "酒店"
        case flight = "航班"
        case route = "路线"
        
        var icon: String {
            switch self {
            case .hotel: return "bed.double"
            case .flight: return "airplane"
            case .route: return "map"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索类型选择器
                SearchTypePicker(selectedType: $selectedSearchType)
                    .padding()
                
                // 搜索表单
                ScrollView {
                    VStack(spacing: 20) {
                        searchFormContent
                    }
                    .padding()
                }
                
                // 搜索结果
                if !searchResults.isEmpty {
                    SearchResultsView(results: searchResults)
                }
            }
            .navigationTitle("智能搜索")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    @ViewBuilder
    private var searchFormContent: some View {
        switch selectedSearchType {
        case .hotel:
            HotelSearchForm(onSearch: performHotelSearch)
        case .flight:
            FlightSearchForm(onSearch: performFlightSearch)
        case .route:
            RouteSearchForm(onSearch: performRouteSearch)
        }
    }
    
    private func performHotelSearch(_ params: HotelSearchParams) {
        isLoading = true
        Task {
            // 调用酒店搜索服务
            let results = await searchHotels(params)
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
            }
        }
    }
    
    private func performFlightSearch(_ params: FlightSearchParams) {
        isLoading = true
        Task {
            // 调用航班搜索服务
            let results = await searchFlights(params)
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
            }
        }
    }
    
    private func performRouteSearch(_ params: RouteSearchParams) {
        isLoading = true
        Task {
            // 调用路线搜索服务
            let results = await searchRoutes(params)
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
            }
        }
    }
}

/// 搜索类型选择器
struct SearchTypePicker: View {
    @Binding var selectedType: SearchFormView.SearchType
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SearchFormView.SearchType.allCases, id: \.self) { type in
                Button(action: {
                    selectedType = type
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: type.icon)
                            .font(.title2)
                        Text(type.rawValue)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedType == type
                        ? Color.blue.opacity(0.1)
                        : Color.clear
                    )
                    .foregroundColor(selectedType == type ? .blue : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

/// 酒店搜索表单
struct HotelSearchForm: View {
    @State private var city = ""
    @State private var location = ""
    @State private var checkinDate = Date()
    @State private var checkoutDate = Date().addingTimeInterval(86400)
    @State private var guests = 2
    @State private var rooms = 1
    
    let onSearch: (HotelSearchParams) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 目的地
            VStack(alignment: .leading, spacing: 8) {
                Text("目的地")
                    .font(.headline)
                
                HStack {
                    TextField("城市", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("具体位置（可选）", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // 入住日期
            VStack(alignment: .leading, spacing: 8) {
                Text("入住日期")
                    .font(.headline)
                
                HStack {
                    DatePicker("入住", selection: $checkinDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("退房", selection: $checkoutDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
            }
            
            // 客人信息
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("客人数")
                        .font(.headline)
                    
                    Stepper("\(guests) 人", value: $guests, in: 1...10)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("房间数")
                        .font(.headline)
                    
                    Stepper("\(rooms) 间", value: $rooms, in: 1...5)
                }
            }
            
            // 搜索按钮
            Button(action: {
                let params = HotelSearchParams(
                    city: city,
                    location: location.isEmpty ? nil : location,
                    checkinDate: checkinDate,
                    checkoutDate: checkoutDate,
                    guests: guests,
                    rooms: rooms
                )
                onSearch(params)
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("搜索酒店")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(city.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(city.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// 航班搜索表单
struct FlightSearchForm: View {
    @State private var fromCity = ""
    @State private var toCity = ""
    @State private var departDate = Date()
    @State private var returnDate: Date?
    @State private var isRoundTrip = false
    @State private var passengers = 1
    @State private var seatClass: SeatClass = .economy
    
    enum SeatClass: String, CaseIterable {
        case economy = "经济舱"
        case business = "商务舱"
        case first = "头等舱"
    }
    
    let onSearch: (FlightSearchParams) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 出发地和目的地
            VStack(alignment: .leading, spacing: 8) {
                Text("航线")
                    .font(.headline)
                
                HStack {
                    TextField("出发城市", text: $fromCity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.blue)
                    
                    TextField("到达城市", text: $toCity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // 出行类型
            Toggle("往返行程", isOn: $isRoundTrip)
                .toggleStyle(SwitchToggleStyle())
            
            // 日期选择
            VStack(alignment: .leading, spacing: 8) {
                Text("日期")
                    .font(.headline)
                
                DatePicker("出发日期", selection: $departDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                
                if isRoundTrip {
                    DatePicker("返程日期", selection: Binding(
                        get: { returnDate ?? departDate.addingTimeInterval(86400) },
                        set: { returnDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                }
            }
            
            // 乘客和舱位
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("乘客数")
                        .font(.headline)
                    
                    Stepper("\(passengers) 人", value: $passengers, in: 1...9)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("舱位等级")
                        .font(.headline)
                    
                    Picker("舱位", selection: $seatClass) {
                        ForEach(SeatClass.allCases, id: \.self) { seatClass in
                            Text(seatClass.rawValue).tag(seatClass)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // 搜索按钮
            Button(action: {
                let params = FlightSearchParams(
                    fromCity: fromCity,
                    toCity: toCity,
                    departDate: departDate,
                    returnDate: isRoundTrip ? returnDate : nil,
                    passengers: passengers,
                    seatClass: seatClass.rawValue
                )
                onSearch(params)
            }) {
                HStack {
                    Image(systemName: "airplane")
                    Text("搜索航班")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(fromCity.isEmpty || toCity.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(fromCity.isEmpty || toCity.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// 路线搜索表单
struct RouteSearchForm: View {
    @State private var destinations = ""
    @State private var startPoint = ""
    @State private var transportMode: TransportMode = .walking
    @State private var optimizeRoute = true
    @State private var returnToStart = false
    
    enum TransportMode: String, CaseIterable {
        case walking = "步行"
        case driving = "驾车"
        case transit = "公交"
        case mixed = "混合"
        
        var icon: String {
            switch self {
            case .walking: return "figure.walk"
            case .driving: return "car"
            case .transit: return "bus"
            case .mixed: return "arrow.triangle.swap"
            }
        }
    }
    
    let onSearch: (RouteSearchParams) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 目的地列表
            VStack(alignment: .leading, spacing: 8) {
                Text("目的地")
                    .font(.headline)
                
                TextField("输入景点名称，用逗号分隔", text: $destinations, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // 起点
            VStack(alignment: .leading, spacing: 8) {
                Text("起点（可选）")
                    .font(.headline)
                
                TextField("起始位置", text: $startPoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 交通方式
            VStack(alignment: .leading, spacing: 8) {
                Text("交通方式")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    ForEach(TransportMode.allCases, id: \.self) { mode in
                        Button(action: {
                            transportMode = mode
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: mode.icon)
                                    .font(.title3)
                                Text(mode.rawValue)
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                transportMode == mode
                                ? Color.blue.opacity(0.1)
                                : Color(.systemGray6)
                            )
                            .foregroundColor(transportMode == mode ? .blue : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // 路线选项
            VStack(spacing: 8) {
                Toggle("自动优化路线顺序", isOn: $optimizeRoute)
                Toggle("返回起点", isOn: $returnToStart)
            }
            
            // 搜索按钮
            Button(action: {
                let params = RouteSearchParams(
                    destinations: destinations,
                    startPoint: startPoint.isEmpty ? nil : startPoint,
                    transportMode: transportMode.rawValue,
                    optimizeRoute: optimizeRoute,
                    returnToStart: returnToStart
                )
                onSearch(params)
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("规划路线")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(destinations.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(destinations.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

/// 搜索结果视图
struct SearchResultsView: View {
    let results: [SearchResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("搜索结果 (\(results.count))")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(results, id: \.id) { result in
                        SearchResultCard(result: result)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxHeight: 400)
        .background(Color(.systemGroupedBackground))
    }
}

/// 搜索结果卡片
struct SearchResultCard: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                    
                    Text(result.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(result.price)
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    if let rating = result.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(rating)
                                .font(.caption)
                        }
                    }
                }
            }
            
            if !result.details.isEmpty {
                Text(result.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 数据模型

struct HotelSearchParams {
    let city: String
    let location: String?
    let checkinDate: Date
    let checkoutDate: Date
    let guests: Int
    let rooms: Int
}

struct FlightSearchParams {
    let fromCity: String
    let toCity: String
    let departDate: Date
    let returnDate: Date?
    let passengers: Int
    let seatClass: String
}

struct RouteSearchParams {
    let destinations: String
    let startPoint: String?
    let transportMode: String
    let optimizeRoute: Bool
    let returnToStart: Bool
}

struct SearchResult {
    let id = UUID()
    let title: String
    let subtitle: String
    let price: String
    let rating: String?
    let details: String
}

// MARK: - 搜索服务（示例实现）

func searchHotels(_ params: HotelSearchParams) async -> [SearchResult] {
    // 这里调用您的 HotelSearchTool
    return [
        SearchResult(
            title: "杭州西湖国际大酒店",
            subtitle: "距离西湖 500m",
            price: "¥688/晚",
            rating: "4.6",
            details: "免费WiFi • 自助早餐 • 游泳池"
        ),
        SearchResult(
            title: "西湖山庄度假酒店",
            subtitle: "距离西湖 800m",
            price: "¥458/晚",
            rating: "4.3",
            details: "花园景观 • 儿童乐园 • 24小时前台"
        )
    ]
}

func searchFlights(_ params: FlightSearchParams) async -> [SearchResult] {
    // 这里调用您的 FlightSearchTool
    return [
        SearchResult(
            title: "东方航空 MU5137",
            subtitle: "08:30 - 10:45",
            price: "¥580",
            rating: nil,
            details: "准点率 85% • 经济舱 • 2小时15分钟"
        )
    ]
}

func searchRoutes(_ params: RouteSearchParams) async -> [SearchResult] {
    // 这里调用您的 RoutePlannerTool
    return [
        SearchResult(
            title: "西湖经典一日游",
            subtitle: "断桥 → 白堤 → 孤山 → 苏堤",
            price: "步行 6.2km",
            rating: nil,
            details: "预计用时 4小时 • 包含 5个景点"
        )
    ]
}
#Preview {
    SearchFormView()
}
