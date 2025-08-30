//
//  SettingView.swift
//  TravelMasterPro
//
//  Created by 珠穆朗玛小蜜蜂 on 2025/8/29.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @AppStorage("model_name") private var modelName: String = "gpt-4"
    @State private var isApiKeyVisible = false
    
    var body: some View {
        Form {
            Section(header: Text("API配置")) {
                if isApiKeyVisible {
                    TextField("OpenAI API Key", text: $apiKey)
                } else {
                    SecureField("OpenAI API Key", text: $apiKey)
                }
                
                Button(action: {
                    isApiKeyVisible.toggle()
                }) {
                    Label(
                        isApiKeyVisible ? "隐藏API Key" : "显示API Key",
                        systemImage: isApiKeyVisible ? "eye.slash" : "eye"
                    )
                }
                
                Picker("模型", selection: $modelName) {
                    Text("GPT-4").tag("gpt-4")
                    Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                }
            }
            
            Section(header: Text("智能体配置")) {
                NavigationLink(destination: AgentSettingsView()) {
                    Text("智能体设置")
                }
            }
            
            Section(header: Text("工作流配置")) {
                NavigationLink(destination: FlowSettingsView()) {
                    Text("工作流设置")
                }
            }
            
            Section(header: Text("关于")) {
                Text("OpenManus iOS版 v1.0")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("设置")
    }
}

struct AgentSettingsView: View {
    var body: some View {
        Form {
            Text("智能体设置")
            // 实现智能体配置选项...
        }
        .navigationTitle("智能体设置")
    }
}

struct FlowSettingsView: View {
    var body: some View {
        Form {
            Text("工作流设置")
            // 实现工作流配置选项...
        }
        .navigationTitle("工作流设置")
    }
}
