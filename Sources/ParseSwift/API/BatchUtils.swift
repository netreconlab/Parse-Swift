//
//  RESTBatchCommand.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

typealias ParseObjectBatchCommand<T> = BatchCommand<T, T> where T: ParseObject
typealias ParseObjectBatchResponse<T> = [(Result<T, ParseError>)]
// swiftlint:disable line_length
typealias RESTBatchCommandType<T> = API.Command<ParseObjectBatchCommand<T>, ParseObjectBatchResponse<T>> where T: ParseObject

typealias ParseObjectBatchCommandNoBody<T> = BatchCommandEncodable<NoBody, NoBody>
typealias ParseObjectBatchResponseNoBody<NoBody> = [(Result<Void, ParseError>)]
typealias RESTBatchCommandNoBodyType<T> = API.NonParseBodyCommand<ParseObjectBatchCommandNoBody<T>, ParseObjectBatchResponseNoBody<T>> where T: Encodable & Sendable

typealias ParseObjectBatchCommandEncodablePointer<T> = BatchChildCommand<T, PointerType> where T: Encodable & Sendable
typealias ParseObjectBatchResponseEncodablePointer<U> = [(Result<PointerType, ParseError>)]
// swiftlint:disable line_length
typealias RESTBatchCommandTypeEncodablePointer<T> = API.NonParseBodyCommand<ParseObjectBatchCommandEncodablePointer<T>, ParseObjectBatchResponseEncodablePointer<Encodable & Sendable>> where T: Encodable & Sendable
 // swiftlint:enable line_length

internal struct BatchCommand<T, U>: ParseEncodable where T: ParseEncodable, U: Sendable & Sendable {
    let requests: [API.Command<T, U>]
    var transaction: Bool
}

internal struct BatchCommandEncodable<T, U>: Encodable where T: Encodable & Sendable, U: Sendable {
    let requests: [API.NonParseBodyCommand<T, U>]
    var transaction: Bool
}

internal struct BatchChildCommand<T, U>: Encodable & Sendable where T: Encodable & Sendable, U: Sendable {
    let requests: [API.BatchCommand<T, U>]
    var transaction: Bool
}

struct BatchUtils {
    static func splitArray<U>(_ array: [U], valuesPerSegment: Int) -> [[U]] {
        if array.count < valuesPerSegment {
            return [array]
        }

        var returnArray = [[U]]()
        var index = 0
        while index < array.count {
            let length = Swift.min(array.count - index, valuesPerSegment)
            let subArray = Array(array[index..<index+length])
            returnArray.append(subArray)
            index += length
        }
        return returnArray
    }
}
