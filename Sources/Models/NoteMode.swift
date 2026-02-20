import SwiftUI

class NoteModeState: ObservableObject {
    @Published var isActive: Bool = false
    @Published var selectedColor: Color = .orange
    @Published var isErasing: Bool = false

    let availableColors: [Color] = [
        .orange, .purple, .green, .cyan, .pink, .yellow
    ]

    func activate() { isActive = true; isErasing = false }
    func deactivate() { isActive = false; isErasing = false }
    func toggleEraser() { isErasing.toggle() }
    func selectColor(_ color: Color) {
        selectedColor = color
        isErasing = false
    }
}
