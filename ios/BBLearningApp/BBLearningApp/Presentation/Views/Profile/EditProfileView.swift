//
//  EditProfileView.swift
//  BBLearning
//
//  Created by Claude Code on 2025-10-15.
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("昵称", text: $viewModel.editedNickname)

                    Picker("年级", selection: $viewModel.editedGrade) {
                        ForEach(7...9, id: \.self) { grade in
                            Text("\(grade)年级").tag(grade)
                        }
                    }

                    Picker("性别", selection: $viewModel.editedGender) {
                        Text("未设置").tag(nil as User.Gender?)
                        ForEach(User.Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender as User.Gender?)
                        }
                    }

                    TextField("学校", text: $viewModel.editedSchool)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.updateProfile()
                        dismiss()
                    }
                    .disabled(viewModel.editedNickname.isEmpty)
                }
            }
        }
    }
}

#if DEBUG
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(viewModel: ProfileViewModel())
    }
}
#endif
