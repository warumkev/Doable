import SwiftUI

struct TimerSetupSheet: View {
    let todoTitle: String
    let onCancel: () -> Void
    let onConfirm: (_ selectedMinutes: Int) -> Void
    
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    // Read the user's preferred default timer minutes from settings
    @AppStorage("settings.defaultTimerMinutes") private var defaultTimerMinutes: Int = 5
    
    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .accessibilityHidden(true)
            
            Text(LocalizedStringKey("timer_setup.title"))
                .font(.headline)
                .padding(.top, 4)
            
            if !todoTitle.isEmpty {
                Text(String(format: NSLocalizedString("timer_setup.for_todo", comment: "for <todo title>"), todoTitle))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                
                HStack(alignment: .center, spacing: 24) {
                    VStack(spacing: 4) {
                        Picker(LocalizedStringKey("timer_setup.minutes_label"), selection: $minutes) {
                            ForEach(0..<60, id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 120)
                        .clipped()
                        Text(LocalizedStringKey("timer_setup.min"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(LocalizedStringKey("timer_setup.colon"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 4) {
                        Picker(LocalizedStringKey("timer_setup.seconds_label"), selection: $seconds) {
                            ForEach(0..<60, id: \.self) { s in
                                Text(String(format: "%02d", s)).tag(s)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 120)
                        .clipped()
                        Text(LocalizedStringKey("timer_setup.sec"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                HStack {
                    Spacer()
                    Text(String(format: "%02d:%02d", minutes, seconds))
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Spacer()
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
            
            HStack(spacing: 12) {
                Button(role: .cancel) {
                    onCancel()
                } label: {
                    Text(LocalizedStringKey("timer_setup.cancel"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                Button {
                    onConfirm(minutes * 60 + seconds)
                } label: {
                    Text(LocalizedStringKey("timer_setup.confirm"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .accessibilityElement(children: .contain)
        .onAppear {
            // Initialize pickers to the user's preferred default (only if still at zero)
            if minutes == 0 && seconds == 0 {
                minutes = max(0, defaultTimerMinutes)
                seconds = 0
            }
        }
    }
}

#Preview {
    TimerSetupSheet(todoTitle: "Buy milk", onCancel: {}, onConfirm: { _ in })
}
