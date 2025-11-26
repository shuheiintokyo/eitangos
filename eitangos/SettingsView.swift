import Foundation
import SwiftUI

struct SettingsView: View {
    @State private var showJapaneseFirst = false
    @State private var selectedLanguage = "ja"
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("学習設定")) {
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
