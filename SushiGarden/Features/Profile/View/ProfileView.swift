// SushiGarden/Features/Profile/View/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    let deps: Dependencies
    let user: UserProfile
    let onLogout: () -> Void
    @StateObject private var vm: ProfileViewModel
    @State private var phone = UserDefaults.standard.string(forKey: "sg.profile.phone") ?? ""

    init(deps: Dependencies, user: UserProfile, onLogout: @escaping () -> Void) {
        self.deps = deps
        self.user = user
        self.onLogout = onLogout
        _vm = StateObject(wrappedValue: ProfileViewModel(user: user, orders: deps.orders))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(vm.user.name)
                        .font(AppFont.sen(20, bold: true))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier(A11y.Profile.name)
                    Text(vm.user.email)
                        .foregroundStyle(AppColor.textSecondary)

                    TextField("Телефон", text: $phone)
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .font(AppFont.sen(15))
                        .padding(.horizontal, Spacing.screenMargin)
                        .onChange(of: phone) { _, newVal in
                            UserDefaults.standard.set(newVal, forKey: "sg.profile.phone")
                        }
                        .accessibilityIdentifier(A11y.Profile.phone)

                    Text("\(Strings.Profile.myOrders): \(vm.recentOrders.count)")
                        .foregroundStyle(.white)

                    Spacer()
                    Button(Strings.Profile.logout, role: .destructive, action: onLogout)
                        .tint(AppColor.accent)
                        .accessibilityIdentifier(A11y.Profile.logout)
                }
                .padding(Spacing.screenMargin)
            }
            .navigationTitle(Strings.Tabs.profile)
            .onAppear { vm.load() }
        }
        .tint(AppColor.accent)
    }
}
