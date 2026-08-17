import Foundation
import ParseSwift
import SwiftUI

struct GameScore: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var points: Int?
    var location: ParseGeoPoint?
    var name: String?
    var myFiles: [ParseFile]?

    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.points,
                                     original: object) {
            updated.points = object.points
        }
        if updated.shouldRestoreKey(\.name,
                                     original: object) {
            updated.name = object.name
        }
        if updated.shouldRestoreKey(\.myFiles,
                                     original: object) {
            updated.myFiles = object.myFiles
        }
        if updated.shouldRestoreKey(\.location,
                                     original: object) {
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

struct ContentView: View {
    @StateObject var viewModel = GameScore.query("points" > 2)
        .order([.descending("points")])
        .viewModel
    @State var name = ""
    @State var points = ""

    var body: some View {
        VStack {
            TextField("Name", text: $name)
            TextField("Points", text: $points)
            Button(action: {
                guard let pointsValue = Int(points),
                      let linkToFile = URL(string: "https://parseplatform.org/img/logo.svg") else {
                    return
                }
                var score = GameScore(name: name, points: pointsValue)
                // Create new ParseFile for saving
                let file1 = ParseFile(name: "file1.svg", cloudURL: linkToFile)
                let file2 = ParseFile(name: "file2.svg", cloudURL: linkToFile)
                score.myFiles = [file1, file2]
                score.save { result in
                    switch result {
                    case .success:
                        Task {
                            await self.viewModel.find()
                        }
                    case .failure(let error):
                        print("Error: \(error.message)")
                    }
                }
            }, label: {
                Text("Save score")
            })
        }
    }
}
