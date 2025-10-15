//
//  LogoGenerator.swift
//  BBLearning
//
//  用于生成App Logo的工具
//

import SwiftUI

struct BBLearningLogo: View {
    var size: CGFloat = 1024

    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),  // 深蓝色
                    Color(red: 0.5, green: 0.3, blue: 0.8)   // 紫色
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: size * 0.05) {
                // 顶部装饰 - 数学符号
                HStack(spacing: size * 0.08) {
                    Text("√")
                        .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))

                    Text("π")
                        .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))

                    Text("∑")
                        .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
                .offset(y: -size * 0.15)

                // 主体 - BB字母
                ZStack {
                    // 背景圆形
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: size * 0.5, height: size * 0.5)

                    // BB文字
                    Text("BB")
                        .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }

                // 底部文字
                Text("数学学习")
                    .font(.system(size: size * 0.08, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .offset(y: size * 0.08)
            }

            // AI装饰元素
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.yellow.opacity(0.6))
                        .frame(width: size * 0.08, height: size * 0.08)
                        .offset(x: -size * 0.12, y: size * 0.12)
                }
                Spacer()
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(size * 0.22) // iOS图标圆角
    }
}

// 预览
#if DEBUG
struct BBLearningLogo_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BBLearningLogo(size: 1024)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("1024x1024")

            BBLearningLogo(size: 180)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("180x180")

            BBLearningLogo(size: 120)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("120x120")
        }
    }
}
#endif
