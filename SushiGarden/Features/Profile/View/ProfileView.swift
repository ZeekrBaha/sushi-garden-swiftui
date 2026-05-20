// TEMP-STUB: replaced in Task 4.3
import SwiftUI

struct ProfileView: View {
    let deps: Dependencies
    let user: UserProfile
    let onLogout: () -> Void

    var body: some View {
        Text(Strings.Tabs.profile).foregroundStyle(AppColor.textPrimary)
    }
}
