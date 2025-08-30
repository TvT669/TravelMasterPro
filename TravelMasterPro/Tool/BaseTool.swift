//
//  BaseTool.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

class BaseTool: Tool {
    let name: String
    let description: String
    private let parameters: [String: Any]
    
    init(name: String, description: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    func execute(arguments: [String: Any]) async throws -> ToolResult {
        // 基类不实现具体逻辑，由子类重写
        fatalError("Subclasses must implement execute method")
    }
    
    func toParameters() -> [String: Any] {
        return [
            "type": "function",
            "function": [
                "name": name,
                "description": description,
                "parameters": [
                    "type": "object",
                    "properties": parameters,
                    "required": Array(parameters.keys)
                ]
            ]
        ]
    }
}
