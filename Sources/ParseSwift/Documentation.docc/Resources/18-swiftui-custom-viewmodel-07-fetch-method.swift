import Foundation
import ParseSwift
import SwiftUI
import Combine

class ViewModel: ObservableObject {
    @Published var objects = [GameScore]()
    @Published var error: ParseError?

    private var subscriptions = Set<AnyCancellable>()

    init() {
        fetchScores()
    }

    func fetchScores() {
        let query = GameScore.query("points" > 2)
            .order([.descending("points")])
        let publisher = query
            .findPublisher()
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    // Publish error
                    self.error = error
                case .finished:
                    print("Successfully queried data")
                }
            },
            receiveValue: {
                // Publish found objects
                self.error = nil
                self.objects = $0
                print("Found \(self.objects.count) objects: \(self.objects)")
            })
        publisher.store(in: &subscriptions)
    }
}
