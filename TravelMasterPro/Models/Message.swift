//
//  Message.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

// 消息模型
struct Message: Identifiable, Codable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let toolCallId: String?
    let name: String?
    let base64Image: String?
    let timestamp: Date
    
    enum MessageRole: String, Codable {
        case system
        case user
        case assistant
        case tool
    }
    
    static func userMessage(_ content: String) -> Message {
        return Message(role: .user, content: content, toolCallId: nil, name: nil, base64Image: nil, timestamp: Date())
    }
    
    static func systemMessage(_ content: String) -> Message {
        return Message(role: .system, content: content, toolCallId: nil, name: nil, base64Image: nil, timestamp: Date())
    }
    
    
      static func assistantMessage(_ content: String) -> Message {
          return Message(role: .assistant, content: content, toolCallId: nil, name: nil, base64Image: nil, timestamp: Date())
      }
    
    static func toolMessage(content: String, toolCallId: String, name: String, base64Image: String? = nil) -> Message {
        return Message(role: .tool, content: content, toolCallId: toolCallId, name: name, base64Image: base64Image, timestamp: Date())
    }
}

// 工具调用
struct ToolCall: Identifiable {
    let id: String
    let function: ToolFunction
    
    struct ToolFunction {
        let name: String
        let arguments: [String: Any]
    }
}

// 工具选择模式
enum ToolChoice {
    case none
    case auto
    case required
}

// 智能体状态
enum AgentState {
    case idle
    case thinking
    case acting
    case finished
    case error(String)
}


