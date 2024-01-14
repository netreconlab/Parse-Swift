//: [Previous](@previous)

//: For this page, make sure your build target is set to ParseSwift and targeting
//: `My Mac` or whatever the name of your mac is. Also be sure your `Playground Settings`
//: in the `File Inspector` is `Platform = macOS`. This is because
//: Keychain in iOS Playgrounds behaves differently. Every page in Playgrounds should
//: be set to build for `macOS` unless specified.

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true

struct User: ParseUser {
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    //: These are required by `ParseUser`.
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    //: Your custom keys.
    var customKey: String?

    /*:
     Optional - implement your own version of merge
     for faster decoding after updating your `ParseObject`.
     */
    func merge(with object: Self) throws -> Self {
        var updated = try mergeParse(with: object)
        if updated.shouldRestoreKey(\.customKey,
                                     original: object) {
            updated.customKey = object.customKey
        }
        return updated
    }
}

Task {
    do {
        try await initializeParse()
    } catch {
        assertionFailure("Error initializing Parse-Swift: \(error)")
    }
    do {
        try await User.logout()
    } catch let error {
        print("Error logging out: \(error)")
    }
}

/*:
 Sign up user asynchronously - Performs work on background
 queue and returns to specified callbackQueue.
 If no callbackQueue is specified it returns to main queue.
*/
User.signup(username: "hello", password: "TestMePass123^") { results in

    switch results {
    case .success(let user):

        Task {
            do {
                let currentUser = try await User.current()
                if !currentUser.hasSameObjectId(as: user) {
                    assertionFailure("Error: these two objects should match")
                } else {
                    print("Successfully signed up user \(user)")
                }
            } catch {
                assertionFailure("Error: current user currently not stored locally")
            }
        }

    case .failure(let error):
        assertionFailure("Error signing up \(error)")
    }
}

//: You can verify the password of the user.
//: Note that usingPost should be set to **true** on newer servers.
User.verifyPassword(password: "TestMePass123^", usingPost: false) { results in

    switch results {
    case .success(let user):
        print(user)

    case .failure(let error):
        print("Error verifying password \(error)")
    }
}

//: Check a bad password
User.verifyPassword(password: "bad", usingPost: false) { results in

    switch results {
    case .success(let user):
        print(user)

    case .failure(let error):
        print("Error verifying password \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
