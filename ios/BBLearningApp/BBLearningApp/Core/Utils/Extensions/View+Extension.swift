//
//  View+Extension.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-13.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension View {

    // MARK: - Loading Overlay

    func loading(_ isLoading: Bool) -> some View {
        ZStack {
            self
            if isLoading {
                LoadingView()
            }
        }
    }

    // MARK: - Error Alert

    func errorAlert(error: Binding<String?>) -> some View {
        alert("错误", isPresented: .constant(error.wrappedValue != nil), presenting: error.wrappedValue) { _ in
            Button("确定") {
                error.wrappedValue = nil
            }
        } message: { errorMessage in
            Text(errorMessage)
        }
    }

    // MARK: - Keyboard Dismissal

    #if canImport(UIKit)
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    // MARK: - Corner Radius

    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    #endif

    // MARK: - Conditional Modifier

    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // MARK: - Navigation

    func hideNavigationBar() -> some View {
        self.navigationBarHidden(true)
    }

    // MARK: - Safe Area

    func ignoresSafeArea() -> some View {
        self.edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Rounded Corner Shape

#if canImport(UIKit)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
#endif

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
}
