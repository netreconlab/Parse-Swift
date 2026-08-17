/*
 Using ParseHookResponse Types:
 
 ParseHookResponse is a generic type that wraps your webhook's
 return value or error. It ensures proper formatting for Parse Server.
 
 Success responses:
 ParseHookResponse(success: value)
 
 Error responses:
 ParseHookResponse<T>(error: parseError)
 
 For complete examples, see:
 https://github.com/netreconlab/parse-server-swift/blob/main/Sources/ParseServerSwift/routes.swift
 
 Example from ParseServerSwift:
 
 // Returning a String result
 return ParseHookResponse(success: "Hello world!")
 
 // Returning an object result
 return ParseHookResponse(success: gameScore)
 
 // Returning a Boolean result (for triggers)
 return ParseHookResponse(success: true)
 
 // Returning an error
 let error = ParseError(code: .otherCause,
                       message: "Something went wrong")
 return ParseHookResponse<String>(error: error)
 */
