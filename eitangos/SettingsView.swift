//
//  SettingsView.swift
//  eitangos
//
//  Settings page
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @State private var showJapaneseFirst = false
    
    // Get app version from Info.plist
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }
    
    // Get build number from Info.plist
    private var buildNumber: String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "1"
    }
    
    // Combined version string
    private var versionString: String {
        return "\(appVersion) (\(buildNumber))"
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("学習設定")) {
                    Toggle(isOn: $showJapaneseFirst) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(.blue)
                            Text("日本語を最初に表示")
                        }
                    }
                }
                
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("アプリバージョン")
                        Spacer()
                        Text(versionString)
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("このアプリについて")
                        }
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

// MARK: - About View
struct AboutView: View {
    // Get app version
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("EITANGOS")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("英単語ズ")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
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
