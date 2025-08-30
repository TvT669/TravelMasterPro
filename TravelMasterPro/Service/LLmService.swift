//
//  LLmService.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation


class LLMService {
    private let apiKey: String
    private let baseURL: URL
    private let model: String
    private let urlSession: URLSession
    
    init(apiKey: String, baseURL: String = "https://api.openai.com/v1", model: String = "gpt-4") {
        self.apiKey = apiKey
        self.baseURL = URL(string: baseURL)!
        self.model = model
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.urlSession = URLSession(configuration: config)
    }
    
    func askTool(messages: [Message], systemMessages: [Message]? = nil, tools: [[String: Any]]? = nil, toolChoice: ToolChoice = .auto) async throws -> (content: String?, toolCalls: [ToolCall]?) {
        // 组合所有消息
        var allMessages = systemMessages ?? []
        allMessages.append(contentsOf: messages)
        
        // 构建请求体
        var requestBody: [String: Any] = [
            "model": model,
            "messages": allMessages.map { formatMessage($0) },
            "temperature": 0.7
        ]
        
        // 添加工具配置
        if let tools = tools {
            requestBody["tools"] = tools
            
            switch toolChoice {
            case .auto:
                requestBody["tool_choice"] = "auto"
            case .required:
                requestBody["tool_choice"] = "required"
            case .none:
                requestBody["tool_choice"] = "none"
            }
        }
        
        // 发送请求
        let data = try await sendRequest(endpoint: "/chat/completions", body: requestBody)
        
        // 解析响应
        let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = responseDict?["choices"] as? [[String: Any]]
        let firstChoice = choices?.first
        let message = firstChoice?["message"] as? [String: Any]
        
        // 提取内容和工具调用
        let content = message?["content"] as? String
        let toolCallsData = message?["tool_calls"] as? [[String: Any]]
        
        // 解析工具调用
        var toolCalls: [ToolCall]?
        if let toolCallsData = toolCallsData, !toolCallsData.isEmpty {
            toolCalls = toolCallsData.compactMap { callData in
                guard let id = callData["id"] as? String,
                      let function = callData["function"] as? [String: Any],
                      let name = function["name"] as? String,
                      let argumentsString = function["arguments"] as? String,
                      let arguments = try? JSONSerialization.jsonObject(with: argumentsString.data(using: .utf8)!) as? [String: Any] else {
                    return nil
                }
                
                return ToolCall(
                    id: id,
                    function: ToolCall.ToolFunction(
                        name: name,
                        arguments: arguments
                    )
                )
            }
        }
        
        return (content, toolCalls)
    }
    
    // 辅助方法: 发送HTTP请求
    private func sendRequest(endpoint: String, body: [String: Any]) async throws -> Data {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw NSError(
                domain: "LLMService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: String(data: data, encoding: .utf8) ?? "Unknown error"]
            )
        }
        
        return data
    }
    
    // 辅助方法: 格式化消息
    private func formatMessage(_ message: Message) -> [String: Any] {
        var formattedMessage: [String: Any] = [
            "role": message.role.rawValue,
            "content": message.content
        ]
        
        if let toolCallId = message.toolCallId {
            formattedMessage["tool_call_id"] = toolCallId
        }
        
        if let name = message.name {
            formattedMessage["name"] = name
        }
        
        return formattedMessage
    }
}
