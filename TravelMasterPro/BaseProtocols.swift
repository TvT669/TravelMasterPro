//
//  BaseProtocols.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

// 工具协议
protocol Tool {
    var name: String { get }
    var description: String { get }
    
    func execute(arguments: [String: Any]) async throws -> ToolResult
    func toParameters() -> [String: Any]
}

// 工具结果
struct ToolResult {
    let output: String?
    let error: String?
    let base64Image: String?
}

// 智能体协议
protocol Agent {
    var name: String { get }
    var systemPrompt: String { get }
    var memory: Memory { get }
    var tools: [Tool] { get }
    
    func run(request: String) async throws -> String
    func think() async throws -> [ToolCall]
    func act(toolCalls: [ToolCall]) async throws -> String
    func cleanup() async
}

// 工作流协议
protocol Flow {
    var primaryAgent: Agent { get }
    var agents: [String: Agent] { get }
    
    func execute(request: String) async throws -> String
}

// 记忆协议
protocol Memory {
    var messages: [Message] { get }
    
    func addMessage(_ message: Message)
    func getContext() -> String
    func clear()
}
