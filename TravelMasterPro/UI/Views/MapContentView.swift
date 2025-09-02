//
//  MapContentView.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/9/2.
//

import SwiftUI
import MapKit

enum DisplayMode {
    case list
    case detail
}

/// 地图内容视图
struct MapContentView: View {
    
    @Binding var selectedTab: Int
    
    // ✅ 添加控制 sheet 显示的状态
    @State private var showingSheet = true
    @State private var selectedDetent: PresentationDetent = .fraction(0.15)
    @State private var query: String = ""
    @State private var locationManager = LocationManager.shared
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isSearching: Bool = false
    @State private var mapItems: [MKMapItem] = []
    @State private var visibleReginon: MKCoordinateRegion?
    @State private var selectedMapItem: MKMapItem?
    @State private var displayMode: DisplayMode = .list
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var route: MKRoute?

    // ✅ 添加默认初始化器（为了兼容预览）
    init(selectedTab: Binding<Int> = .constant(2)) {
        self._selectedTab = selectedTab
    }
    
    private func search() async {
        do {
            mapItems = try await performSearch(searchTerm: query, visibleRegion: visibleReginon)
            isSearching = false
        } catch {
            mapItems = []
            print(error.localizedDescription)
            isSearching = false
        }
    }
    
    private func requestCalculateDirections() async {
        route = nil
        if let selectedMapItem {
            guard let currentUserLocation = locationManager.manager.location else { return }
            let startingMapItem = MKMapItem(placemark: MKPlacemark(coordinate: currentUserLocation.coordinate))
            self.route = await calculationDirections(from:startingMapItem, to: selectedMapItem)
        }
    }
    
    // ✅ 处理返回操作
    private func handleBackAction() {
        // 先关闭 sheet
        withAnimation(.easeOut(duration: 0.2)) {
            showingSheet = false
        }
        
        // 延迟执行返回操作，等待 sheet 关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 0
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack{
                Map(position: $position, selection: $selectedMapItem){
                    ForEach(mapItems,id:\.self) { mapItem in
                        Marker(item: mapItem)
                    }
                    if let route {
                        MapPolyline(route)
                            .stroke(.blue, lineWidth: 5)
                    }
                    UserAnnotation()
                    
                }
                .onChange(of: locationManager.region, {
                    withAnimation {
                        position = .region(locationManager.region)
                    }
                })
                // ✅ 修改为可控制的 sheet
                .sheet(isPresented: $showingSheet, content: {
                    VStack {
                        // ✅ 添加顶部控制栏
                        HStack {
                            Button("隐藏") {
                                withAnimation {
                                    showingSheet = false
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // 拖拽指示器
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.secondary.opacity(0.4))
                                .frame(width: 40, height: 6)
                            
                            Spacer()
                            
                            Button("刷新") {
                                Task {
                                    isSearching = true
                                    await search()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        switch displayMode {
                        case .list:
                            SearchBarView(search: $query, isSearching: $isSearching)
                            PlaceListView(mapItems: mapItems,selectedMapItem: $selectedMapItem)
                        case .detail:
                            SelectedPlaceDetailView(mapItem: $selectedMapItem)
                                .padding()
                            if selectedDetent == .medium || selectedDetent == .large{
                                if let selectedMapItem {
                                    ActionButtons(mapItem: selectedMapItem)
                                        .padding()
                                }
                               
                                LookAroundPreview(initialScene: lookAroundScene)
                            }
                              
                        }
                       
                        Spacer()
                    }
                    .presentationDetents([.fraction(0.15), .medium, .large],selection: $selectedDetent)
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled(false)  // ✅ 允许交互式关闭
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                })
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        handleBackAction()  // ✅ 使用新的返回处理方法
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                            Text("返回")
                                .font(.body)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // ✅ 添加右侧工具栏
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            withAnimation {
                                position = .userLocation(fallback: .automatic)
                            }
                        }) {
                            Label("回到当前位置", systemImage: "location")
                        }
                        
                        Button(action: {
                            mapItems.removeAll()
                            query = ""
                            selectedMapItem = nil
                        }) {
                            Label("清除搜索", systemImage: "xmark.circle")
                        }
                        
                        Button(action: {
                            withAnimation {
                                showingSheet.toggle()
                            }
                        }) {
                            Label(showingSheet ? "隐藏面板" : "显示面板", systemImage: showingSheet ? "eye.slash" : "eye")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onChange(of: selectedMapItem, {
                if selectedMapItem != nil {
                    displayMode = .detail
                } else {
                    displayMode = .list
                }
            })
            .onMapCameraChange { context in
                visibleReginon = context.region
            }
            .task(id: selectedMapItem) {
                lookAroundScene = nil
                if let selectedMapItem{
                    let request = MKLookAroundSceneRequest(mapItem: selectedMapItem)
                    lookAroundScene = try? await request.scene
                   await requestCalculateDirections()
                }
            }
            .task(id: isSearching,{
                if isSearching {
                    await search()
                }
            })
            // ✅ 当页面出现时重新显示 sheet
            .onAppear {
                if !showingSheet {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showingSheet = true
                    }
                }
            }
        }
    }
}

// ✅ 添加预览
#Preview {
    MapContentView()
}




