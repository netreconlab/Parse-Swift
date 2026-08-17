import Foundation
import ParseSwift
import SwiftUI
import Combine

// Create a SwiftUI view
struct ContentView: View {

    // A view model in SwiftUI
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
        }
    }
}
