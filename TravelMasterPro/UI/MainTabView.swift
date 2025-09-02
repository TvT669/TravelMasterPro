//
//  MainTabView.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/9/2.
//

import SwiftUI

/// 主导航视图 - 整合所有功能模块
struct MainTabView: View {
    @StateObject private var appState = AppState()
    @StateObject private var locationManager = LocationManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // AI 助手页面 - 使用您现有的完整功能页面
            LegacyContentView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI 助手")
                }
                .tag(0)
            
            // 搜索表单页面
            SearchFormView()
                .tabItem {
                    Image(systemName: "magnifyingglass.circle")
                    Text("搜索")
                }
                .tag(1)
            
            // 地图导航页面
            MapContentView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "map")
                    Text("地图")
                }
                .tag(2)
            
            // 我的行程页面
            TripPlannerView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("行程")
                }
                .tag(3)
            
            // 用户页面
           UserProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("我的")
                }
                .tag(4)
        }
        .environmentObject(locationManager)
        .accentColor(.blue)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToMainTab"))) { notification in
            if let tabIndex = notification.object as? Int {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = tabIndex
                }
            }
        }
    }
        
}

#Preview {
    MainTabView()
}


