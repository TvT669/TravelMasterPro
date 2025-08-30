//
//  GeneralAgent.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

class GeneralAgent: BaseAgent {
    static let systemPrompt = """
    你是一个通用智能助手。你可以使用多种工具来解决问题。
    当你需要执行特定操作时，请使用提供给你的工具。
    如果需要搜索信息、执行计算或其他操作，请明确表明你将使用哪些工具。
    """
    
    static func create(llm: LLMService) -> GeneralAgent {
        // 创建通用工具集
        let tools: [Tool] = [
            CalculatorTool(),
            WebSearchTool(),
            FileOperatorTool(),
            TerminateTool()
        ]
        
        return GeneralAgent(
            name: "GeneralAgent",
            systemPrompt: systemPrompt,
            tools: tools,
            llm: llm
        )
    }
}
