import Foundation
import ParseSwift

// Create a Hook Function with a function name and webhook URL
var myFunction = ParseHookFunction(
    name: "foo",
    url: URL(string: "https://api.example.com/foo")!
)
