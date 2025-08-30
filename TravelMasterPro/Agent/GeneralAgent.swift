//
//  GeneralAgent.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

/// 通用智能体 - 多功能SUV
/// 集成了文本生成、基础分析等通用功能
class GeneralAgent: ToolCallAgent {
    
    static func create(llm: LLMService) -> GeneralAgent {
        let systemPrompt = """
        你是一个通用智能助手，具备以下能力：
        1. 文本生成和编辑
        2. 问题解答
        3. 数据分析
        4. 任务规划
        
        你可以处理各种类型的请求，如果需要专业工具支持，请使用相应的工具。
        """
        
        let tools: [Tool] = [
            
            PlanningTool()
        ]
        
        let capabilities: [AgentCapability] = [
            .textGeneration,
            .dataAnalysis
        ]
        
        return GeneralAgent(
            name: "GeneralAgent",
            systemPrompt: systemPrompt,
            capabilities: capabilities,
            tools: tools,
            llm: llm
        )
    }
}
