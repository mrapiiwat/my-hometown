//
//  ContentView.swift
//  my-hometown
//
//  Created by Apiwat Lantong on 21/11/2568 BE.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { msg in
                            HStack(spacing: 8) {
                                if msg.isUser { Spacer() }
                                
                                Text(msg.text)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(msg.isUser ? Color.black : Color(.systemGray6))
                                    .foregroundColor(msg.isUser ? .white : .black)
                                    .cornerRadius(8)
                                    .lineLimit(nil)
                                
                                if !msg.isUser { Spacer() }
                            }
                            .id(msg.id)
                        }
                        
                        if isLoading {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 4) {
                                        ForEach(0..<3, id: \.self) { i in
                                            Circle()
                                                .fill(Color.gray)
                                                .frame(width: 6, height: 6)
                                                .scaleEffect(1.0 + sin(CGFloat(i) * .pi / 3) * 0.3)
                                                .animation(
                                                    Animation.easeInOut(duration: 0.6)
                                                        .repeatForever()
                                                        .delay(Double(i) * 0.1),
                                                    value: isLoading
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                Spacer()
                            }
                            .id("loading")
                        }
                    }
                    .padding(12)
                }
                .onChange(of: messages.count) {
                    withAnimation {
                        if let lastId = messages.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isLoading) {
                    if isLoading {
                        proxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 6) {
                TextField("Message", text: $inputText)
                    .textFieldStyle(.plain)
                    .disabled(isLoading)
                    .onSubmit { sendMessage() }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(inputText.isEmpty || isLoading ? Color.gray.opacity(0.5) : Color.black)
                        .cornerRadius(6)
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding(10)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Hometown")
        .navigationBarTitleDisplayMode(.inline)
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        let question = inputText
        inputText = ""
        isLoading = true

        guard let url = URL(string: "http://127.0.0.1:5000/ask") else {
            messages.append(ChatMessage(text: "Connection failed", isUser: false))
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["question": question])

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false))
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let answer = json["answer"] as? String else {
                    messages.append(ChatMessage(text: "No data found", isUser: false))
                    return
                }

                messages.append(ChatMessage(text: answer, isUser: false))
            }
        }.resume()
    }
}

#Preview {
    NavigationView {
        ContentView()
    }
}
