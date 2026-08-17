import Foundation
import ParseSwift
import SwiftUI
import Combine

// Create a custom view model that queries GameScore's
class ViewModel: ObservableObject {
    @Published var objects = [GameScore]()
    @Published var error: ParseError?

    private var subscriptions = Set<AnyCancellable>()
}
