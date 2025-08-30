//
//  PlanningFlow.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

class PlanningFlow: Flow {
    let primaryAgent: Agent
    let agents: [String: Agent]
    private let planningTool: PlanningTool
    private var activePlanId: String?
    
    init(primaryAgent: Agent, agents: [String: Agent]) {
        self.primaryAgent = primaryAgent
        self.agents = agents
        self.planningTool = PlanningTool()
        
        // 确保每个智能体的工具集包含规划工具
        for (_, agent) in agents {
            if let baseAgent = agent as? BaseAgent {
                if !(baseAgent.tools.contains(where: { $0 is PlanningTool })) {
                    // 添加规划工具 (这需要BaseAgent的tools属性是可变的)
                    // 这里假设BaseAgent提供了一个添加工具的方法
                }
            }
        }
    }
    
    func execute(request: String) async throws -> String {
        // 生成计划ID
        activePlanId = "plan_\(UUID().uuidString)"
        
        // 创建初始计划
        try await createInitialPlan(request: request)
        
        // 执行计划
        var results: [String] = []
        var currentStep = 0
        
        while let step = try await getNextStep() {
            // 获取步骤类型和内容
            let (stepType, stepContent) = extractTypeFromStep(step)
            
            // 获取合适的执行智能体
            let executor = getExecutor(stepType: stepType)
            
            // 标记步骤为进行中
            try await markStepInProgress(stepIndex: currentStep)
            
            // 执行步骤
            let stepResult = try await executeStep(
                agent: executor,
                stepContent: stepContent,
                stepIndex: currentStep
            )
            
            // 保存结果
            results.append(stepResult)
            
            // 标记步骤为已完成
            try await markStepCompleted(stepIndex: currentStep)
            
            currentStep += 1
        }
        
        // 获取最终结果
        let finalResult = try await finalizePlan()
        results.append(finalResult)
        
        return results.joined(separator: "\n\n")
    }
    
    // 创建初始计划
    private func createInitialPlan(request: String) async throws {
        guard let planId = activePlanId else { return }
        
        // 使用主智能体创建计划
        let planPrompt = """
        请为以下请求创建一个执行计划，将任务分解为具体步骤：
        
        \(request)
        
        对于每个步骤，请添加类型标记，如：
        1. [GENERAL] 分析需求
        2. [DATA] 处理数据
        3. [GENERAL] 生成报告
        """
        
        // 将规划请求发送给主智能体
        let planResult = try await primaryAgent.run(request: planPrompt)
        
        // 解析步骤
        let steps = parseSteps(from: planResult)
        
        // 创建计划
        _ = try await planningTool.execute(arguments: [
            "command": "create",
            "plan_id": planId,
            "title": "Plan for: \(request)",
            "steps": steps
        ])
    }
    
    // 获取下一个未完成的步骤
    private func getNextStep() async throws -> String? {
        guard let planId = activePlanId else { return nil }
        
        let planResult = try await planningTool.execute(arguments: [
            "command": "get",
            "plan_id": planId
        ])
        
        guard let planOutput = planResult.output else { return nil }
        
        // 解析计划输出以获取下一个未完成的步骤
        // 这里简化处理，实际实现可能需要更复杂的解析
        let lines = planOutput.split(separator: "\n")
        
        for line in lines {
            if line.contains("◯") {  // 未开始的步骤
                // 提取步骤内容
                if let stepContent = line.split(separator: "◯").last?.trimmingCharacters(in: .whitespaces) {
                    return stepContent
                }
            }
        }
        
        return nil  // 没有更多步骤
    }
    
    // 执行步骤
    private func executeStep(agent: Agent, stepContent: String, stepIndex: Int) async throws -> String {
        // 获取计划状态
        guard let planId = activePlanId else {
            return "计划ID不存在"
        }
        
        let planResult = try await planningTool.execute(arguments: [
            "command": "get",
            "plan_id": planId
        ])
        
        let planStatus = planResult.output ?? "计划状态未知"
        
        // 构建步骤提示
        let stepPrompt = """
        当前计划状态:
        \(planStatus)
        
        你的当前任务:
        你正在执行步骤 \(stepIndex + 1): "\(stepContent)"
        
        请完成这个步骤并报告结果。
        """
        
        // 执行步骤
        return try await agent.run(request: stepPrompt)
    }
    
    // 标记步骤为进行中
    private func markStepInProgress(stepIndex: Int) async throws {
        guard let planId = activePlanId else { return }
        
        _ = try await planningTool.execute(arguments: [
            "command": "mark_step",
            "plan_id": planId,
            "step_index": stepIndex,
            "step_status": "in_progress"
        ])
    }
    
    // 标记步骤为已完成
    private func markStepCompleted(stepIndex: Int) async throws {
        guard let planId = activePlanId else { return }
        
        _ = try await planningTool.execute(arguments: [
            "command": "mark_step",
            "plan_id": planId,
            "step_index": stepIndex,
            "step_status": "completed"
        ])
    }
    
    // 完成计划
    private func finalizePlan() async throws -> String {
        guard let planId = activePlanId else {
            return "计划ID不存在"
        }
        
        let planResult = try await planningTool.execute(arguments: [
            "command": "get",
            "plan_id": planId
        ])
        
        return "任务已完成。总结:\n\(planResult.output ?? "")"
    }
    
    // 从步骤中提取类型
    private func extractTypeFromStep(_ step: String) -> (String, String) {
        // 查找形如 [TYPE] 的标记
        let pattern = "\\[(\\w+)\\]\\s*(.*)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        
        if let match = regex?.firstMatch(
            in: step,
            options: [],
            range: NSRange(location: 0, length: step.utf16.count)
        ) {
            let typeRange = Range(match.range(at: 1), in: step)!
            let contentRange = Range(match.range(at: 2), in: step)!
            
            let type = String(step[typeRange])
            let content = String(step[contentRange])
            
            return (type.uppercased(), content)
        }
        
        // 没有类型标记，返回默认类型
        return ("GENERAL", step)
    }
    
    // 获取执行智能体
    private func getExecutor(stepType: String) -> Agent {
        return agents[stepType.lowercased()] ?? primaryAgent
    }
    
    // 从文本解析步骤
    private func parseSteps(from text: String) -> [String] {
        var steps: [String] = []
        let lines = text.split(separator: "\n")
        
        for line in lines {
            // 查找形如 "1. [TYPE] 步骤内容" 的行
            let pattern = "\\d+\\.\\s*\\[?\\w*\\]?\\s*(.*)"
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            
            if let match = regex?.firstMatch(
                in: String(line),
                options: [],
                range: NSRange(location: 0, length: line.utf16.count)
            ) {
                if let range = Range(match.range(at: 0), in: line) {
                    steps.append(String(line[range]))
                }
            }
        }
        
        return steps.isEmpty ? ["分析问题", "执行任务", "验证结果"] : steps
    }
}
