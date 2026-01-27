import Foundation
import ParseSwift
import SwiftUI
import Combine

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?
    
    var points: Int?
    var location: ParseGeoPoint?
    var name: String?
    
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points, original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.name, original: object) {
            updated.name = object.name
        }
        if updated.shouldRestoreKey(\.location, original: object) {
            updated.location = object.location
        }
        return updated
    }
}

extension GameScore {
    init(name: String, points: Int) {
        self.name = name
        self.points = points
    }
}

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
                    self.error = error
                case .finished:
                    print("Successfully queried data")
                }
            },
            receiveValue: {
                self.objects = $0
                print("Found \(self.objects.count), objects: \(self.objects)")
            })
        publisher.store(in: &subscriptions)
    }
}

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            if let error = viewModel.error {
                Text(error.description)
            } else {
                List(viewModel.objects, id: \.id) { object in
                    VStack(alignment: .leading) {
                        Text("Points: \(String(describing: object.points))")
                            .font(.headline)
                        if let createdAt = object.createdAt {
                            Text("\(createdAt.description)")
                        }
                    }
                }
            }
            Spacer()
        }
    }
}
