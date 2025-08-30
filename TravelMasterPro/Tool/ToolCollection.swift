//
//  ToolCollection.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

class ToolCollection {
    private var tools: [Tool] = []
    private var toolMap: [String: Tool] = [:]
    
    init(tools: [Tool] = []) {
        for tool in tools {
            addTool(tool)
        }
    }
    
    func addTool(_ tool: Tool) {
        if toolMap[tool.name] == nil {
            tools.append(tool)
            toolMap[tool.name] = tool
        }
    }
    
    func getTool(name: String) -> Tool? {
        return toolMap[name]
    }
    
    func getAllTools() -> [Tool] {
        return tools
    }
    
    func toParameters() -> [[String: Any]] {
        return tools.map { $0.toParameters() }
    }
    
    func execute(name: String, arguments: [String: Any]) async throws -> ToolResult {
        guard let tool = toolMap[name] else {
            return ToolResult(output: nil, error: "工具 \(name) 不存在", base64Image: nil)
        }
        
        return try await tool.execute(arguments: arguments)
    }
}
