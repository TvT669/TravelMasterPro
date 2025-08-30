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

   // 应用状态管理
   class AppState: ObservableObject {
       @Published var isLoggedIn = false
       @Published var isLoading = false
       @Published var errorMessage: String? = nil
       
       // LLM 服务
       let llmService: LLMService
       
       // 智能体
       let generalAgent: GeneralAgent
              
       // 工作流
       var planningFlow: PlanningFlow?
       
       init() {
           // 从安全存储加载API密钥
           let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
           
           // 初始化LLM服务
           self.llmService = LLMService(apiKey: apiKey)
           
           // 初始化智能体
           self.generalAgent = GeneralAgent.create(llm: llmService)
           
           // 创建工作流
           self.planningFlow = PlanningFlow(
               primaryAgent: generalAgent,
               agents: [
                   "general": generalAgent,
                   
               ]
           )
       }
       
       // 执行请求
       func executeRequest(_ request: String) async {
           guard let flow = planningFlow else { return }
           
           DispatchQueue.main.async {
               self.isLoading = true
               self.errorMessage = nil
           }
           
           do {
               let result = try await flow.execute(request: request)
               
               DispatchQueue.main.async {
                   self.isLoading = false
               }
               
               // 处理结果...
           } catch {
               DispatchQueue.main.async {
                   self.isLoading = false
                   self.errorMessage = error.localizedDescription
               }
           }
       }
   }
