//
//  QuestionAnswerViewModel.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import Foundation
import Combine

final class QuestionAnswerViewModel: BaseViewModel {
    @Published var questions: [Question]
    @Published var currentIndex: Int = 0
    @Published var userAnswers: [String] = []
    @Published var isAnswered: Bool = false
    @Published var feedback: AnswerFeedback?

    @Published var showExitAlert = false
    @Published var showResultView = false
    @Published var practiceResult: PracticeResult?

    private let submitAnswerUseCase: SubmitAnswerUseCase

    var currentQuestion: Question {
        return questions[currentIndex]
    }

    var currentUserAnswer: String {
        get {
            guard currentIndex < userAnswers.count else { return "" }
            return userAnswers[currentIndex]
        }
        set {
            if currentIndex < userAnswers.count {
                userAnswers[currentIndex] = newValue
            } else {
                // 扩展数组到当前索引
                while userAnswers.count <= currentIndex {
                    userAnswers.append("")
                }
                userAnswers[currentIndex] = newValue
            }
            isAnswered = false
            feedback = nil
        }
    }

    var progress: Double {
        return Double(currentIndex + 1) / Double(questions.count)
    }

    var progressText: String {
        return "\(currentIndex + 1)/\(questions.count)"
    }

    var hasNext: Bool {
        return currentIndex < questions.count - 1
    }

    var hasPrevious: Bool {
        return currentIndex > 0
    }

    var canSubmit: Bool {
        return !currentUserAnswer.trimmed.isEmpty && !isAnswered
    }

    init(
        questions: [Question],
        submitAnswerUseCase: SubmitAnswerUseCase = DIContainer.shared.resolve(SubmitAnswerUseCase.self)
    ) {
        self.questions = questions
        self.submitAnswerUseCase = submitAnswerUseCase
        super.init()

        // 初始化答案数组
        self.userAnswers = Array(repeating: "", count: questions.count)
    }

    // MARK: - Navigation

    func nextQuestion() {
        guard hasNext else { return }
        currentIndex += 1
        updateAnsweredState()
    }

    func previousQuestion() {
        guard hasPrevious else { return }
        currentIndex -= 1
        updateAnsweredState()
    }

    private func updateAnsweredState() {
        // 检查当前题目是否已经提交过
        isAnswered = feedback != nil && currentIndex < userAnswers.count && !userAnswers[currentIndex].isEmpty
    }

    // MARK: - Submit Answer

    func submitAnswer() {
        guard canSubmit else { return }

        executeTask(
            submitAnswerUseCase.execute(
                questionId: currentQuestion.id,
                answer: currentUserAnswer
            ),
            onSuccess: { [weak self] feedback in
                self?.feedback = feedback
                self?.isAnswered = true

                // 自动跳转到下一题（延迟2秒）
                if feedback.isCorrect && (self?.hasNext ?? false) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.nextQuestion()
                    }
                }
            }
        )
    }

    // MARK: - Complete Practice

    func finishPractice() {
        // 计算统计信息
        let answeredQuestions = questions.enumerated().filter { index, _ in
            index < userAnswers.count && !userAnswers[index].isEmpty
        }

        let totalAnswered = answeredQuestions.count
        let correctCount = answeredQuestions.filter { index, question in
            // 简化判断：假设已提交的题目才有feedback
            // 实际应该从已提交的记录中获取
            return true // TODO: 从practice records获取实际正确数
        }.count

        let result = PracticeResult(
            totalQuestions: questions.count,
            answeredCount: totalAnswered,
            correctCount: correctCount,
            totalTime: 0, // TODO: 添加计时功能
            knowledgePoints: Set(questions.map { $0.knowledgePointId })
        )

        practiceResult = result
        showResultView = true
    }

    func exitPractice() {
        showExitAlert = true
    }

    func confirmExit() {
        // 父视图负责dismiss
        showExitAlert = false
    }

    // MARK: - Helpers

    func isQuestionAnswered(_ index: Int) -> Bool {
        return index < userAnswers.count && !userAnswers[index].isEmpty
    }

    func getAnswerStatus(_ index: Int) -> AnswerStatus {
        guard isQuestionAnswered(index) else {
            return .notAnswered
        }

        // TODO: 从已提交的记录中获取正确性
        return .answered
    }

    enum AnswerStatus {
        case notAnswered
        case answered
        case correct
        case wrong
    }
}

// MARK: - Practice Result

struct PracticeResult {
    let totalQuestions: Int
    let answeredCount: Int
    let correctCount: Int
    let totalTime: TimeInterval
    let knowledgePoints: Set<Int>

    var accuracy: Double {
        guard answeredCount > 0 else { return 0 }
        return Double(correctCount) / Double(answeredCount)
    }

    var accuracyText: String {
        return String(format: "%.1f%%", accuracy * 100)
    }

    var scoreText: String {
        return "\(correctCount)/\(totalQuestions)"
    }

    var completionRate: Double {
        return Double(answeredCount) / Double(totalQuestions)
    }

    var grade: Grade {
        if accuracy >= 0.9 { return .excellent }
        if accuracy >= 0.8 { return .good }
        if accuracy >= 0.6 { return .pass }
        return .fail
    }

    enum Grade {
        case excellent  // 优秀
        case good       // 良好
        case pass       // 及格
        case fail       // 不及格

        var displayName: String {
            switch self {
            case .excellent: return "优秀"
            case .good: return "良好"
            case .pass: return "及格"
            case .fail: return "不及格"
            }
        }

        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .pass: return "orange"
            case .fail: return "red"
            }
        }
    }
}

// MARK: - Answer Feedback (if not defined in Domain)

struct AnswerFeedback: Codable {
    let isCorrect: Bool
    let score: Double
    let standardAnswer: String
    let explanation: String?
    let hints: [String]?
}
