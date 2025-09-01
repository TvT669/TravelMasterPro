//
//  TravelMasterProApp.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import SwiftUI
import SwiftData

@main
struct TravelMasterProApp: App {
    @StateObject private var appState = AppState()
       
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - 应用状态管理

/// 应用全局状态管理器
/// 负责协调智能体、工作流和UI状态
class AppState: ObservableObject {
    // MARK: - UI 状态
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var response = "" // ✅ ContentView 需要的响应属性
    @Published var errorMessage: String? = nil
    
    // MARK: - 服务层
    private let llmService: LLMService
    private let memoryService: MemoryService
    private let toolCollection: ToolCollection
    // MARK: - 智能体
    private let generalAgent: GeneralAgent
    private let flightAgent: FlightAgent
    private let hotelAgent: HotelAgent
    private let routeAgent: RouteAgent // ✅ 修正名称
    private let budgetAgent: BudgetAgent
    
    // MARK: - 工作流
    private var planningFlow: PlanningFlow?
    
    // MARK: - 初始化
    
    init() {
        // 从安全存储加载API密钥
        let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        
        // 初始化服务
        self.llmService = LLMService()
        self.memoryService = MemoryService()
        self.toolCollection = ToolCollection.createTravelSuite()
        
        // 初始化智能体
        self.generalAgent = GeneralAgent.create(llm: llmService)
        self.flightAgent = FlightAgent.create(llm: llmService)
        self.hotelAgent = HotelAgent.create(llm: llmService)
        self.routeAgent = RouteAgent.create(llm: llmService)
        self.budgetAgent = BudgetAgent.create(llm: llmService)
        
        // 创建工作流
        self.planningFlow = PlanningFlow(
            primaryAgent: generalAgent,
            agents: [
                "general": generalAgent,
                "flight": flightAgent,
                "hotel": hotelAgent,
                "route": routeAgent,
                "budget": budgetAgent
            ]
        )
        
        // ✅ 直接在这里配置记忆服务，而不是调用方法
        // 配置记忆服务参数
        // memoryService.configure(maxMessages: 100)
        // memoryService.enableContextTracking(true)
    }
    
    // MARK: - 公共方法
    
    /// 执行用户请求
    /// - Parameter request: 用户输入的请求文本
    @MainActor
    func executeRequest(_ request: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 构建消息
            let userMessage = Message.userMessage(request)
            let messages = [userMessage]
            
            // 获取可用工具
            let availableTools = toolCollection.getAllTools()
            
            // ✅ 使用新的工具调用方法
            let result = try await llmService.thinkAndAct(
                messages: messages,
                availableTools: availableTools
            )
            
            response = result.content ?? "处理完成"
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = "执行请求失败: \(error.localizedDescription)"
            print("🔍 详细错误: \(error)")
        }
    }
    
    /// 清空对话历史
    func clearConversation() {
        response = ""
        memoryService.clear()
        errorMessage = nil
    }
    
    /// 获取对话上下文
    func getConversationContext() -> String {
        return memoryService.getContext()
    }
    
    /// ✅ 修复 4: 重新连接服务 - 简化实现
    func reconnectServices() async {
        isLoading = true
        
        do {
            // 测试连接 - 使用现有的 completion 方法
            let testMessage = Message(role: .user, content: "测试连接")
            _ = try await llmService.completion(messages: [testMessage])
            
            isLoading = false
            errorMessage = nil
            
        } catch {
            isLoading = false
            errorMessage = "重新连接失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 配置方法
    
    /// 更新API密钥
    func updateApiKey(_ newApiKey: String) {
        UserDefaults.standard.set(newApiKey, forKey: "openai_api_key")
        
        // ✅ 修复 5: 直接更新API密钥
        llmService.updateApiKey(newApiKey)
        
        // 重新连接服务
        Task {
            await reconnectServices()
        }
    }
    
    /// 获取系统状态摘要
    func getSystemStatus() -> SystemStatus {
        return SystemStatus(
            isConnected: !isLoading && errorMessage == nil,
            memoryUsage: memoryService.getEnhancedMessages().count,
            lastError: errorMessage,
            agentCount: 5 // 当前智能体数量
        )
    }
    
    // MARK: - 私有方法
    
    private func setupMemoryService() {
        // 配置记忆服务参数
        // 这里可以根据需要调整记忆配置
    }
}

// MARK: - 辅助数据结构

/// 系统状态信息
struct SystemStatus {
    let isConnected: Bool
    let memoryUsage: Int
    let lastError: String?
    let agentCount: Int
    
    var statusDescription: String {
        if isConnected {
            return "🟢 系统正常运行"
        } else if let error = lastError {
            return "🔴 系统异常: \(error)"
        } else {
            return "🟡 系统连接中..."
        }
    }
}
