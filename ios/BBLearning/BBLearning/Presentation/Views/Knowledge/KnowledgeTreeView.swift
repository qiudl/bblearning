//
//  KnowledgeTreeView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI

struct KnowledgeTreeView: View {
    @StateObject private var viewModel = KnowledgeTreeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            SearchBar(text: $viewModel.searchText, placeholder: "搜索知识点")
                .padding()

            // 年级选择
            if !viewModel.isSearching {
                GradePicker(selectedGrade: $viewModel.selectedGrade, onChange: viewModel.changeGrade)
                    .padding(.horizontal)
            }

            // 内容
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isSearching {
                SearchResultsList(results: viewModel.searchResults)
            } else {
                KnowledgeTreeList(knowledgePoints: viewModel.knowledgeTree)
            }
        }
        .navigationTitle("知识点")
        .errorAlert(error: $viewModel.errorMessage)
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct GradePicker: View {
    @Binding var selectedGrade: Int
    var onChange: (Int) -> Void

    var body: some View {
        Picker("年级", selection: $selectedGrade) {
            Text("七年级").tag(7)
            Text("八年级").tag(8)
            Text("九年级").tag(9)
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedGrade) { newValue in
            onChange(newValue)
        }
    }
}

struct KnowledgeTreeList: View {
    let knowledgePoints: [KnowledgePoint]

    var body: some View {
        List(knowledgePoints) { kp in
            NavigationLink(destination: KnowledgeDetailView(knowledgePoint: kp)) {
                KnowledgePointRow(knowledgePoint: kp)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct SearchResultsList: View {
    let results: [KnowledgePoint]

    var body: some View {
        if results.isEmpty {
            VStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("未找到相关知识点")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(results) { kp in
                NavigationLink(destination: KnowledgeDetailView(knowledgePoint: kp)) {
                    KnowledgePointRow(knowledgePoint: kp)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct KnowledgePointRow: View {
    let knowledgePoint: KnowledgePoint

    var body: some View {
        HStack(spacing: 12) {
            // 难度指示器
            Circle()
                .fill(Color.forDifficulty(knowledgePoint.difficulty.rawValue))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(knowledgePoint.name)
                    .font(.body)

                if let progress = knowledgePoint.progress {
                    HStack(spacing: 8) {
                        ProgressBar(value: progress.masteryLevel)
                            .frame(height: 4)
                        Text("\(Int(progress.masteryLevel * 100))%")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            Spacer()

            if knowledgePoint.hasChildren {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProgressBar: View {
    var value: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))

                Rectangle()
                    .fill(Color.forProgress(value))
                    .frame(width: geometry.size.width * CGFloat(value))
            }
        }
        .cornerRadius(2)
    }
}

#if DEBUG
struct KnowledgeTreeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            KnowledgeTreeView()
        }
    }
}
#endif
