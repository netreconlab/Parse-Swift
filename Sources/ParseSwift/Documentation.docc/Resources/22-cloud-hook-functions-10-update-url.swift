import Foundation
import ParseSwift

var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)

// Update the webhook URL to point to a new endpoint
myFunction.url = URL(string: "https://api.example.com/bar")!
