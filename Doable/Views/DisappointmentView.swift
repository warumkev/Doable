import SwiftUI

struct DisappointmentView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let buttonTitle: LocalizedStringKey
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "face.dashed")
                    .font(.system(size: 72))
                    .foregroundColor(.primary)
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Spacer()
                Button(action: { onConfirm() }) {
                    Text(buttonTitle)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.bottom, 30)
            }
            .padding()
        }
    }
}

#Preview {
    DisappointmentView(title: "Timer cancelled", message: "This wasn't very Doable of you.", buttonTitle: "OK", onConfirm: {})
}
