//
//  PlanningTool.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

class PlanningTool: BaseTool {
    // 计划存储
    private var plans: [String: [String: Any]] = [:]
    
    init() {
        super.init(
            name: "planning",
            description: "用于创建和管理任务执行计划",
            parameters: [
                "command": [
                    "type": "string",
                    "enum": ["create", "update", "list", "get", "mark_step", "delete"],
                    "description": "要执行的命令"
                ],
                "plan_id": [
                    "type": "string",
                    "description": "计划ID"
                ],
                "title": [
                    "type": "string",
                    "description": "计划标题"
                ],
                "steps": [
                    "type": "array",
                    "items": [
                        "type": "string"
                    ],
                    "description": "计划步骤列表"
                ],
                "step_index": [
                    "type": "integer",
                    "description": "步骤索引"
                ],
                "step_status": [
                    "type": "string",
                    "enum": ["not_started", "in_progress", "completed", "blocked"],
                    "description": "步骤状态"
                ]
            ]
        )
    }
    
    override func execute(arguments: [String: Any]) async throws -> ToolResult {
        guard let command = arguments["command"] as? String else {
            return ToolResult(output: nil, error: "缺少command参数", base64Image: nil)
        }
        
        switch command {
        case "create":
            return try createPlan(arguments)
        case "get":
            return getPlan(arguments)
        case "mark_step":
            return markStep(arguments)
        // 实现其他命令...
        default:
            return ToolResult(output: nil, error: "未知命令: \(command)", base64Image: nil)
        }
    }
    
    private func createPlan(_ args: [String: Any]) throws -> ToolResult {
        guard let planId = args["plan_id"] as? String,
              let title = args["title"] as? String,
              let steps = args["steps"] as? [String] else {
            return ToolResult(output: nil, error: "缺少必要参数", base64Image: nil)
        }
        
        // 创建计划
        var plan: [String: Any] = [
            "title": title,
            "steps": steps,
            "step_statuses": Array(repeating: "not_started", count: steps.count),
            "step_notes": Array(repeating: "", count: steps.count),
            "created_at": Date()
        ]
        
        // 保存计划
        plans[planId] = plan
        
        return ToolResult(output: "计划创建成功: \(title)", error: nil, base64Image: nil)
    }
    
    private func getPlan(_ args: [String: Any]) -> ToolResult {
        guard let planId = args["plan_id"] as? String else {
            return ToolResult(output: nil, error: "缺少计划ID", base64Image: nil)
        }
        
        guard let plan = plans[planId] else {
            return ToolResult(output: nil, error: "计划不存在: \(planId)", base64Image: nil)
        }
        
        // 格式化计划
        let title = plan["title"] as? String ?? "无标题"
        let steps = plan["steps"] as? [String] ?? []
        let statuses = plan["step_statuses"] as? [String] ?? []
        
        var result = "计划: \(title)\n"
        
        for (i, step) in steps.enumerated() {
            let status = i < statuses.count ? statuses[i] : "未知"
            let statusSymbol = getStatusSymbol(status)
            result += "\(i+1). \(statusSymbol) \(step)\n"
        }
        
        return ToolResult(output: result, error: nil, base64Image: nil)
    }
    
    private func markStep(_ args: [String: Any]) -> ToolResult {
        guard let planId = args["plan_id"] as? String,
              let stepIndex = args["step_index"] as? Int,
              let stepStatus = args["step_status"] as? String else {
            return ToolResult(output: nil, error: "缺少必要参数", base64Image: nil)
        }
        
        guard var plan = plans[planId] as? [String: Any] else {
            return ToolResult(output: nil, error: "计划不存在: \(planId)", base64Image: nil)
        }
        
        guard var statuses = plan["step_statuses"] as? [String],
              stepIndex >= 0 && stepIndex < statuses.count else {
            return ToolResult(output: nil, error: "步骤索引无效", base64Image: nil)
        }
        
        statuses[stepIndex] = stepStatus
        plan["step_statuses"] = statuses
        plans[planId] = plan
        
        return ToolResult(output: "步骤\(stepIndex + 1)状态更新为: \(stepStatus)", error: nil, base64Image: nil)
    }
    
    // 辅助方法: 获取状态符号
    private func getStatusSymbol(_ status: String) -> String {
        switch status {
        case "not_started":
            return "◯"
        case "in_progress":
            return "⚙️"
        case "completed":
            return "✓"
        case "blocked":
            return "⚠️"
        default:
            return "?"
        }
    }
}
