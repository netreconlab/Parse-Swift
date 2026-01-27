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
}
