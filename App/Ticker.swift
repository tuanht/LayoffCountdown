import Foundation

/// Separate from `AppModel` so views that only read settings, like settings form, are not redrawn every second.
@MainActor
final class Ticker: ObservableObject {
    @Published private(set) var now = Date.now

    init() { start() }

    /// Fires on whole seconds so label flips together with widget's system timer.
    /// `.common` mode keeps ticking while dropdown menu tracks.
    private func start() {
        let nextSecond = Date(timeIntervalSinceReferenceDate: Date.now.timeIntervalSinceReferenceDate.rounded(.up))
        let timer = Timer(fire: nextSecond, interval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.now = .now }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
