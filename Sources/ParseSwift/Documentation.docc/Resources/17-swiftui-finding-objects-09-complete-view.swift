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
    @State var isShowingAction = false
    @State var savedLabel = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Name", text: $name)
                TextField("Points", text: $points)
                Button(action: {
                    guard let pointsValue = Int(points),
                          let linkToFile = URL(string: "https://parseplatform.org/img/logo.svg") else {
                        return
                    }
                    var score = GameScore(name: name, points: pointsValue)
                    let file1 = ParseFile(name: "file1.svg", cloudURL: linkToFile)
                    let file2 = ParseFile(name: "file2.svg", cloudURL: linkToFile)
                    score.myFiles = [file1, file2]
                    score.save { result in
                        switch result {
                        case .success:
                            savedLabel = "Saved score"
                            Task {
                                await self.viewModel.find()
                            }
                        case .failure(let error):
                            savedLabel = "Error: \(error.message)"
                        }
                        isShowingAction = true
                    }
                }, label: {
                    Text("Save score")
                })
            }
            if let error = viewModel.error {
                Text(error.description)
            } else {
                List(viewModel.results, id: \.id) { result in
                    VStack(alignment: .leading) {
                        Text("Points: \(result.points ?? 0)")
                            .font(.headline)
                        if let createdAt = result.createdAt {
                            Text("\(createdAt.description)")
                        }
                    }
                }
            }
            Spacer()
        }.task {
            await viewModel.find()
        }.alert(isPresented: $isShowingAction) {
            Alert(title: Text("GameScore"),
                  message: Text(savedLabel),
                  dismissButton: .default(Text("Ok")))
        }
    }
}
