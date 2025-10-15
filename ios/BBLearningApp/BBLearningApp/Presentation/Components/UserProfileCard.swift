//
//  UserProfileCard.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI

struct UserProfileCard: View {
    let user: User?
    let stats: UserStats?
    let onEditProfile: () -> Void
    let onChangeAvatar: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 头像和基本信息
            HStack(spacing: 16) {
                Button(action: onChangeAvatar) {
                    ZStack(alignment: .bottomTrailing) {
                        if let avatarURL = user?.avatarURL {
                            AsyncImage(url: avatarURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                defaultAvatar
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            defaultAvatar
                        }

                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .offset(x: 4, y: 4)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(user?.displayName ?? "学生")
                            .font(.title2)
                            .fontWeight(.bold)

                        Button(action: onEditProfile) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    HStack(spacing: 12) {
                        Label(user?.gradeText ?? "7年级", systemImage: "graduationcap")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let gender = user?.gender {
                            Label(gender.displayName, systemImage: genderIcon(for: gender))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding()

            // 等级信息
            if let user = user {
                let levelInfo = user.levelInfo

                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 4) {
                            Text("LV.\(levelInfo.level)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)

                            Text(levelInfo.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(levelInfo.currentExp)/\(levelInfo.nextLevelExp) EXP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))

                            // 进度条
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(levelInfo.progress))
                                .animation(.easeInOut(duration: 0.5), value: levelInfo.progress)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal)
            }

            // 学习数据
            if let stats = stats {
                HStack(spacing: 0) {
                    StatItemView(
                        value: "\(stats.studyDays)",
                        label: "学习天数",
                        icon: "calendar"
                    )

                    Divider()
                        .frame(height: 40)

                    StatItemView(
                        value: "\(stats.totalQuestions)",
                        label: "完成题目",
                        icon: "checkmark.circle"
                    )

                    Divider()
                        .frame(height: 40)

                    StatItemView(
                        value: stats.accuracyPercentage,
                        label: "平均正确率",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                .padding()
                .background(Color.surface)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 80, height: 80)
            .foregroundColor(.gray)
    }

    private func genderIcon(for gender: User.Gender) -> String {
        switch gender {
        case .male: return "person"
        case .female: return "person.fill"
        case .other: return "person.crop.circle"
        }
    }
}

// MARK: - StatItemView

struct StatItemView: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#if DEBUG
struct UserProfileCard_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileCard(
            user: User(
                id: 1,
                username: "testuser",
                nickname: "测试用户",
                grade: 7,
                avatar: nil,
                phone: nil,
                email: nil,
                gender: .male,
                school: "示范中学",
                experience: 500,
                createdAt: Date(),
                updatedAt: Date()
            ),
            stats: UserStats(
                studyDays: 30,
                totalQuestions: 500,
                averageAccuracy: 0.85,
                currentStreak: 7,
                longestStreak: 15
            ),
            onEditProfile: {},
            onChangeAvatar: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif
