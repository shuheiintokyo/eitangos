import Foundation
import SwiftUI

struct SettingsView: View {
    @State private var soundEnabled = true
    @State private var showJapaneseFirst = false
    @State private var selectedLanguage = "ja"
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("学習設定")) {
                    Toggle("音声を有効にする", isOn: $soundEnabled)
                    
                    Picker("表示順序", selection: $showJapaneseFirst) {
                        Text("英語を最初に表示").tag(false)
                        Text("日本語を最初に表示").tag(true)
                    }
                }
                
                Section(header: Text("言語設定")) {
                    Picker("言語", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("日本語").tag("ja")
                    }
                }
                
                Section(header: Text("その他")) {
                    HStack {
                        Text("アプリバージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Text("このアプリについて")
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("EITANGOS")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("英単語ズ")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("アプリについて")
                    .font(.headline)
                
                Text("EITANGOSは、効率的に英単語を学習するためのシンプルで使いやすいアプリです。リスト表示、クイックテスト、設定機能を備えています。")
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("このアプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }
}
