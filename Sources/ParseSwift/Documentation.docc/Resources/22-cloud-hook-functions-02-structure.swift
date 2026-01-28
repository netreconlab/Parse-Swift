import Foundation
import ParseSwift

/*
 ParseHookFunction represents a webhook registration
 for a cloud function. It consists of a function name
 and a URL where Parse Server will send requests.
 */
var hookFunction = ParseHookFunction(
    name: "myFunction",
    url: URL(string: "https://api.example.com/functions/myFunction")!
)
