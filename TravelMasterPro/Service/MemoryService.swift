//
//  MemoryService.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import Foundation

class MemoryService: Memory {
    private(set) var messages: [Message] = []
    private let maxMessageCount: Int
    
    init(maxMessageCount: Int = 100) {
        self.maxMessageCount = maxMessageCount
    }
    
    func addMessage(_ message: Message) {
        messages.append(message)
        
        // 如果消息数量超过最大值，移除最旧的非系统消息
        if messages.count > maxMessageCount {
            let nonSystemMessages = messages.filter { $0.role != .system }
            let systemMessages = messages.filter { $0.role == .system }
            
            if nonSystemMessages.count > 0 {
                messages = systemMessages + nonSystemMessages.dropFirst()
            }
        }
    }
    
    func getContext() -> String {
        return messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n\n")
    }
    
    func clear() {
        messages.removeAll(where: { $0.role != .system })
    }
}
