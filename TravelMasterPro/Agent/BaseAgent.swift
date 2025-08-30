//
//  BaseAgent.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

class BaseAgent: Agent {
    let name: String
    let systemPrompt: String
    let memory: Memory
    let tools: [Tool]
    private let toolCollection: ToolCollection
    private let llm: LLMService
    
    init(name: String,
         systemPrompt: String,
         memory: Memory = MemoryService(),
         tools: [Tool] = [],
         llm: LLMService) {
        self.name = name
        self.systemPrompt = systemPrompt
        self.memory = memory
        self.tools = tools
        self.toolCollection = ToolCollection(tools: tools)
        self.llm = llm
    }
    
    func run(request: String) async throws -> String {
        // 添加用户请求到记忆
        memory.addMessage(Message.userMessage(request))
        
        // 添加系统提示
        if memory.messages.first?.role != .system {
            memory.addMessage(Message.systemMessage(systemPrompt))
        }
        
        // 开始循环
        var steps = 0
        let maxSteps = 10
        
        while steps < maxSteps {
            steps += 1
            
            // 思考阶段
            let toolCalls = try await think()
            
            // 如果没有工具调用，则返回结果
            if toolCalls.isEmpty {
                return memory.messages.last(where: { $0.role == .assistant })?.content ?? "无法生成回复"
            }
            
            // 行动阶段
            let result = try await act(toolCalls: toolCalls)
            
            // 如果行动结束，返回结果
            if toolCalls.contains(where: { $0.function.name == "terminate" }) {
                return result
            }
        }
        
        return "达到最大步骤限制"
    }
    
    func think() async throws -> [ToolCall] {
        // 调用LLM进行思考
        let result = try await llm.askTool(
            messages: memory.messages,
            tools: toolCollection.toParameters(),
            toolChoice: .auto
        )
        
        // 如果有内容，添加到记忆
        if let content = result.content {
            memory.addMessage(Message(
                role: .assistant,
                content: content,
                toolCallId: nil,
                name: nil,
                base64Image: nil,
                timestamp: Date()
            ))
        }
        
        // 返回工具调用
        return result.toolCalls ?? []
    }
    
    func act(toolCalls: [ToolCall]) async throws -> String {
        var results: [String] = []
        
        // 执行每个工具调用
        for call in toolCalls {
            let result = try await toolCollection.execute(
                name: call.function.name,
                arguments: call.function.arguments
            )
            
            // 将结果添加到记忆
            let resultContent = result.output ?? result.error ?? "工具执行无输出"
            memory.addMessage(Message.toolMessage(
                content: resultContent,
                toolCallId: call.id,
                name: call.function.name,
                base64Image: result.base64Image
            ))
            
            results.append(resultContent)
        }
        
        // 返回结果摘要
        return results.joined(separator: "\n")
    }
    
    func cleanup() async {
        // 默认实现，子类可以重写
    }
}
