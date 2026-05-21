import SwiftUI

struct CheckoutView: View {
    let deps: Dependencies
    let total: Int
    @StateObject private var vm: CheckoutViewModel
    @State private var goTracking = false

    init(deps: Dependencies, total: Int) {
        self.deps = deps
        self.total = total
        _vm = StateObject(wrappedValue: CheckoutViewModel(cart: deps.cart, orders: deps.orders))
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: Spacing.md) {
                    field(Strings.Auth.name, $vm.name, A11y.Checkout.name)
                    field(Strings.Checkout.phone, $vm.phone, A11y.Checkout.phone, .phonePad)
                    field(Strings.Auth.email, $vm.email, A11y.Checkout.email, .emailAddress)
                    summaryRow(Strings.Cart.sum, vm.subtotal)
                    summaryRow(Strings.Cart.delivery, vm.deliveryFee)
                    summaryRow(Strings.Cart.serviceFee, vm.serviceFee)
                    summaryRow(Strings.Cart.total, vm.total, bold: true)
                    Button { Task { await vm.confirm() } } label: {
                        Text(Strings.Cart.confirm)
                            .font(AppFont.sectionHeader).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(AppColor.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!vm.canConfirm)
                    .accessibilityIdentifier(A11y.Checkout.confirm)
                }
                .padding(.horizontal, Spacing.screenMargin).padding(.top, Spacing.md)
            }
            .navigationDestination(isPresented: $goTracking) { TrackingView(deps: deps) }
        }
        .navigationTitle(Strings.Checkout.address)
        .onChange(of: vm.didConfirm) { _, ok in if ok { goTracking = true } }
    }

    private func field(_ label: String, _ text: Binding<String>, _ id: String,
                       _ kb: UIKeyboardType = .default) -> some View {
        TextField("", text: text, prompt: Text(label).foregroundColor(AppColor.textSecondary))
            .keyboardType(kb).padding().background(Color.white.opacity(0.06))
            .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier(id)
    }

    private func summaryRow(_ label: String, _ value: Int, bold: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text("\(value) \(Strings.currency)")
                .font(bold ? AppFont.price : AppFont.weight)
                .foregroundStyle(.white)
        }
    }
}
