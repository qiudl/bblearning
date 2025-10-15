//
//  BreadcrumbView.swift
//  BBLearningApp
//
//  Created by Claude Code on 2025-10-15.
//  面包屑导航组件
//

import SwiftUI

/// 面包屑导航视图
struct BreadcrumbView: View {
    let path: [KnowledgePoint]

    var body: some View {
        if !path.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(path.enumerated()), id: \.element.id) { index, point in
                        NavigationLink(destination: KnowledgeDetailView(knowledgePoint: point)) {
                            Text(point.name)
                                .font(.caption)
                                .foregroundColor(index == path.count - 1 ? .primary : .secondary)
                                .lineLimit(1)
                        }

                        if index < path.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGray6))
        }
    }
}

/// 紧凑型面包屑导航（用于详情页顶部）
struct CompactBreadcrumbView: View {
    let path: [KnowledgePoint]

    var body: some View {
        if path.count > 1 {
            HStack(spacing: 4) {
                Image(systemName: "house.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ForEach(Array(path.dropLast().enumerated()), id: \.element.id) { index, point in
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text(point.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BreadcrumbView_Previews: PreviewProvider {
    static var mockPath: [KnowledgePoint] {
        [
            KnowledgePoint(
                id: 1,
                name: "七年级数学",
                grade: 7,
                parentId: nil,
                level: 1,
                sortOrder: 1,
                description: nil,
                difficulty: .easy,
                children: nil,
                progress: nil
            ),
            KnowledgePoint(
                id: 2,
                name: "有理数",
                grade: 7,
                parentId: 1,
                level: 2,
                sortOrder: 1,
                description: nil,
                difficulty: .easy,
                children: nil,
                progress: nil
            ),
            KnowledgePoint(
                id: 3,
                name: "有理数的加减法",
                grade: 7,
                parentId: 2,
                level: 3,
                sortOrder: 1,
                description: nil,
                difficulty: .medium,
                children: nil,
                progress: nil
            )
        ]
    }

    static var previews: some View {
        VStack(spacing: 20) {
            Text("标准面包屑导航")
                .font(.headline)

            BreadcrumbView(path: mockPath)

            Text("紧凑型面包屑导航")
                .font(.headline)

            CompactBreadcrumbView(path: mockPath)

            Spacer()
        }
        .padding()
    }
}
#endif
