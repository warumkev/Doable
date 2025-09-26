import SwiftUI

struct TimerSetupSheet: View {
    let todoTitle: String
    let onCancel: () -> Void
    let onConfirm: (_ selectedMinutes: Int) -> Void
    
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .accessibilityHidden(true)
            
            Text("Set a timer")
                .font(.headline)
                .padding(.top, 4)
            
            if !todoTitle.isEmpty {
                Text("for \(todoTitle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                
                HStack(alignment: .center, spacing: 24) {
                    VStack(spacing: 4) {
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60, id: \.self) { m in
                                Text(String(format: "%02d", m)).tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 120)
                        .clipped()
                        Text("min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(":")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 4) {
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60, id: \.self) { s in
                                Text(String(format: "%02d", s)).tag(s)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 120)
                        .clipped()
                        Text("sec")
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
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                Button {
                    onConfirm(minutes * 60 + seconds)
                } label: {
                    Text("Confirm")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
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
    }
}

#Preview {
    TimerSetupSheet(todoTitle: "Buy milk", onCancel: {}, onConfirm: { _ in })
}
