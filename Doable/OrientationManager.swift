import SwiftUI

final class OrientationManager: ObservableObject {
    @Published var mask: InterfaceOrientationMask = .all
    
    func allowAll() { mask = .all }
    func forcePortrait() { mask = .portrait }
    func forceLandscape() { mask = .landscape }
}
