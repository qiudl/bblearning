//
//  SolutionStepsView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI

/// 解题步骤可视化视图
struct SolutionStepsView: View {
    let steps: [SolutionStep]
    @State private var currentStep: Int = 0
    @State private var showAllSteps: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.blue)
                Text("解题步骤")
                    .font(.headline)

                Spacer()

                Button(showAllSteps ? "逐步查看" : "显示全部") {
                    showAllSteps.toggle()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            if showAllSteps {
                // 显示所有步骤
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    StepCard(step: step, isHighlighted: index == currentStep)
                }
            } else {
                // 逐步显示
                StepCard(step: steps[currentStep], isHighlighted: true)

                // 导航按钮
                HStack {
                    Button(action: previousStep) {
                        Label("上一步", systemImage: "chevron.left")
                    }
                    .disabled(currentStep == 0)

                    Spacer()

                    Text("\(currentStep + 1)/\(steps.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: nextStep) {
                        Label("下一步", systemImage: "chevron.right")
                            .labelStyle(.trailingIcon)
                    }
                    .disabled(currentStep >= steps.count - 1)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }

    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }

    private func previousStep() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
        }
    }
}

struct StepCard: View {
    let step: SolutionStep
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 步骤标题
            HStack {
                Text("步骤 \(step.stepNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)

                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // 描述
            Text(step.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // 公式（如果有）
            if let formula = step.formula {
                Text(formula)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }

            // 结果（如果有）
            if let result = step.result {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(result)
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }

            // 解释（如果有）
            if let explanation = step.explanation {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(explanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(isHighlighted ? Color.blue.opacity(0.05) : Color.background)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHighlighted ? Color.blue : Color.clear, lineWidth: 2)
        )
        .cornerRadius(8)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

#if DEBUG
struct SolutionStepsView_Previews: PreviewProvider {
    static var previews: some View {
        SolutionStepsView(steps: SolutionStepManager().parseSolutionSteps(from: ""))
            .padding()
    }
}
#endif
