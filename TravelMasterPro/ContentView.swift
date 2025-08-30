//
//  ContentView.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var userInput = ""
    @State private var chatMessages: [DisplayMessage] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // 聊天消息区域
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(chatMessages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if appState.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatMessages.count) { _ in
                        if let lastMessage = chatMessages.last {
                            scrollView.scrollTo(lastMessage.id)
                        }
                    }
                }
                
                // 输入区域
                HStack {
                    TextField("输入你的问题...", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(appState.isLoading)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.isLoading)
                }
                .padding()
            }
            .navigationTitle("AI")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .alert(isPresented: .constant(appState.errorMessage != nil)) {
                Alert(
                    title: Text("错误"),
                    message: Text(appState.errorMessage ?? "未知错误"),
                    dismissButton: .default(Text("确定")) {
                        appState.errorMessage = nil
                    }
                )
            }
        }
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // 添加用户消息到UI
        let userMessage = DisplayMessage(
            id: UUID().uuidString,
            role: .user,
            content: userInput,
            timestamp: Date()
        )
        chatMessages.append(userMessage)
        
        // 保存用户输入并清空输入框
        let input = userInput
        userInput = ""
        
        // 执行请求
        Task {
            await appState.executeRequest(input)
        }
    }
}

// 消息展示模型
struct DisplayMessage: Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    var base64Image: String? = nil
    
    enum MessageRole {
        case user
        case assistant
        case system
    }
}

// 消息视图
struct MessageView: View {
    let message: DisplayMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(10)
                    .background(backgroundColor)
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(10)
                
                if let base64Image = message.base64Image,
                   let imageData = Data(base64Encoded: base64Image),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(10)
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    private var backgroundColor: Color {
        switch message.role {
        case .user:
            return .blue
        case .assistant:
            return Color(.systemGray5)
        case .system:
            return Color(.systemGray6)
        }
    }
}
