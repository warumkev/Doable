import SwiftUI

import SwiftUI

struct Achievement {
    let id: String
    let titleKey: LocalizedStringKey
    let descriptionKey: LocalizedStringKey
    let unlockTextKey: LocalizedStringKey
    var unlocked: Bool = false
}

struct AchievementsView: View {
    var todos: [Todo] = []

    private var computedAchievements: [Achievement] {
        let completedTodos = todos.filter { $0.isCompleted }
        let completedCount = completedTodos.count
        let empireDone = completedTodos.contains { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).localizedCompare("Ein Imperium aufbauen") == .orderedSame }
        let earlyBird = completedTodos.contains { $0.completedAt != nil && Calendar.current.component(.hour, from: $0.completedAt!) < 8 }

        // Workaholic: total focus time (not implemented, fallback to 0)
        let totalFocusSeconds = 0 // TODO: Replace with actual timer runtime aggregation
        let workaholic = totalFocusSeconds >= 36000

        // Sprint-Weltmeister: 10 tasks in one hour, each with no timer or timer <= 1 min (not implemented, fallback to false)
        let sprinter = false // TODO: Implement if timer info per todo is available

        return [
            Achievement(
                id: "maker",
                titleKey: "achievement.maker.title",
                descriptionKey: "achievement.maker.desc",
                unlockTextKey: "achievement.maker.unlock",
                unlocked: completedCount >= 100
            ),
            Achievement(
                id: "workaholic",
                titleKey: "achievement.workaholic.title",
                descriptionKey: "achievement.workaholic.desc",
                unlockTextKey: "achievement.workaholic.unlock",
                unlocked: workaholic
            ),
            Achievement(
                id: "empire",
                titleKey: "achievement.empire.title",
                descriptionKey: "achievement.empire.desc",
                unlockTextKey: "achievement.empire.unlock",
                unlocked: empireDone
            ),
            Achievement(
                id: "sprinter",
                titleKey: "achievement.sprinter.title",
                descriptionKey: "achievement.sprinter.desc",
                unlockTextKey: "achievement.sprinter.unlock",
                unlocked: sprinter
            ),
            Achievement(
                id: "earlybird",
                titleKey: "achievement.earlybird.title",
                descriptionKey: "achievement.earlybird.desc",
                unlockTextKey: "achievement.earlybird.unlock",
                unlocked: earlyBird
            )
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(LocalizedStringKey("achievements.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 32)
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(computedAchievements, id: \ .id) { achievement in
                            achievementCard(achievement)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .padding()
            .navigationTitle(LocalizedStringKey("achievements.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func achievementCard(_ achievement: Achievement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(achievement.titleKey)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                if achievement.unlocked {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                }
            }
            Text(achievement.descriptionKey)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Divider()
            Text(achievement.unlockTextKey)
                .font(.footnote)
                .foregroundColor(achievement.unlocked ? .accentColor : .secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        .opacity(achievement.unlocked ? 1.0 : 0.5)
    }
}

#Preview {
    AchievementsView(todos: [])
}
