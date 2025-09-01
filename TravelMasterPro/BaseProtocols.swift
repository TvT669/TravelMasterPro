//
//  BaseProtocols.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/31.
//

import Foundation

// MARK: - 智能体底盘协议

/// 智能体协议 - 汽车底盘规范
/// 只定义"什么是智能体"，不定义"怎么工作"
protocol Agent {
    var name: String { get }
    var capabilities: [AgentCapability] { get }
    var status: AgentStatus { get }
    
    // 唯一的核心接口 - 执行任务
    func run(request: String) async throws -> String
    
    // 工作流协作接口
    func setSharedContext(_ context: [String: Any])
    func getSharedContext() -> [String: Any]
    
    // 能力查询
    func isCapableOf(_ capability: AgentCapability) -> Bool
}

/// 智能体能力枚举
enum AgentCapability: String, CaseIterable {
    case flightSearch = "flight_search"
    case hotelBooking = "hotel_booking"
    case routePlanning = "route_planning"
    case budgetPlanning = "budget_planning"
    case textGeneration = "text_generation"
    case dataAnalysis = "data_analysis"
    case webSearch = "web_search"
    case travelPlanning = "travel_planning" 
}

/// 智能体状态
enum AgentStatus: Equatable {
    case idle
    case working
    case error(String)
    
    static func == (lhs: AgentStatus, rhs: AgentStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.working, .working):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - 工作流协议

/// 工作流协议 - 任务总指挥
/// 负责"做什么"和"怎么组织"
protocol Flow {
    var name: String { get }
    var status: FlowStatus { get }
    
    // 核心工作流方法
    func execute(request: String) async throws -> FlowResult
    func cancel() async
    func getProgress() -> FlowProgress
}

/// 工作流状态
enum FlowStatus: Equatable {
    case idle
    case planning      // 规划中
    case executing     // 执行中
    case completed     // 完成
    case failed(String) // 失败
    case cancelled     // 取消
    
    static func == (lhs: FlowStatus, rhs: FlowStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.planning, .planning), (.executing, .executing),
             (.completed, .completed), (.cancelled, .cancelled):
            return true
        case (.failed(let a), (.failed(let b))):
            return a == b
        default:
            return false
        }
    }
}

/// 工作流执行结果
struct FlowResult {
    let success: Bool
    let output: String
    let executionTime: TimeInterval
    let tasksCompleted: Int
    let metadata: [String: Any]?
}

/// 工作流进度
struct FlowProgress {
    let currentTask: String?
    let percentage: Double
    let estimatedTimeRemaining: TimeInterval?
}

// MARK: - 工具协议

/// 工具协议 - 具体功能实现
protocol Tool {
    var name: String { get }
    var description: String { get }
    
    func execute(arguments: [String: Any]) async throws -> ToolResult
    func toParameters() -> [String: Any]
}

/// 工具执行结果
struct ToolResult {
    let output: String?
    let error: String?
    let base64Image: String?
    let metadata: [String: Any]?
    
    init(output: String? = nil, error: String? = nil, base64Image: String? = nil, metadata: [String: Any]? = nil) {
        self.output = output
        self.error = error
        self.base64Image = base64Image
        self.metadata = metadata
    }
}

// MARK: - 任务系统

/// 任务类型
enum TaskType: String, CaseIterable {
    case flight = "flight"
    case hotel = "hotel"
    case route = "route"
    case budget = "budget"
    case general = "general"
}

/// 简单任务
struct SimpleTask {
    let id: String
    let type: TaskType
    let description: String
    let assignedAgent: String
    var status: TaskStatus
    var result: String?
    
    enum TaskStatus {
        case pending, running, completed, failed
    }
}

// MARK: - 记忆协议

/// 记忆协议
protocol Memory {
    var messages: [Message] { get }
    
    func addMessage(_ message: Message)
    func getContext() -> String
    func clear()
}

// MARK: - 错误系统

/// 智能体错误
enum AgentError: Error, LocalizedError {
    case executionFailed(String)
    case capabilityMismatch(required: AgentCapability, available: [AgentCapability])
    case invalidRequest(String)
    case concurrentExecution
    case maxStepsExceeded
    
    var errorDescription: String? {
        switch self {
        case .executionFailed(let message):
            return "执行失败: \(message)"
        case .capabilityMismatch(let required, let available):
            return "能力不匹配，需要: \(required.rawValue)，可用: \(available.map(\.rawValue).joined(separator: ", "))"
        case .invalidRequest(let request):
            return "无效请求: \(request)"
        case .concurrentExecution:
            return "智能体正在执行其他任务"
        case .maxStepsExceeded:
            return "达到最大执行步骤限制"
        }
    }
}

/// 工作流错误
enum FlowError: Error, LocalizedError {
    case agentNotFound(String)
    case executionTimeout
    case invalidConfiguration
    case taskDecompositionFailed
    
    var errorDescription: String? {
        switch self {
        case .agentNotFound(let name):
            return "未找到智能体: \(name)"
        case .executionTimeout:
            return "执行超时"
        case .invalidConfiguration:
            return "配置无效"
        case .taskDecompositionFailed:
            return "任务分解失败"
        }
    }
}
