import Foundation

struct SavedGame: Identifiable, Codable {
    let id: UUID
    let date: Date
    let difficulty: String
    /// Flat array of 81 solution values.
    let solutions: [Int]
    /// Flat array of 81 bools: true = given.
    let givens: [Bool]
    /// Flat array of 81 optionals: player answers.
    let playerValues: [Int?]

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var progress: String {
        let filled = zip(givens, playerValues).filter { $0.0 || $0.1 != nil }.count
        return "\(filled)/81"
    }
}

class GameHistoryStore: ObservableObject {
    @Published var games: [SavedGame] = []

    private let key = "sudoku_game_history"

    init() { load() }

    func save(game: SavedGame) {
        // Keep max 50 games.
        games.insert(game, at: 0)
        if games.count > 50 { games = Array(games.prefix(50)) }
        persist()
    }

    func remove(at offsets: IndexSet) {
        games.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedGame].self, from: data) else { return }
        games = decoded
    }
}
