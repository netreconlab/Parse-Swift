//
//  LiveQueryConstants.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/3/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 Represents an update on a specific object from the `ParseLiveQuery` Server.
 - Entered: The object has been updated, and is now included in the query.
 - Left:    The object has been updated, and is no longer included in the query.
 - Created: The object has been created, and is a part of the query.
 - Updated: The object has been updated, and is still a part of the query.
 - Deleted: The object has been deleted, and is no longer included in the query.
 */
public enum Event<T: ParseObject>: Equatable, Sendable {
    /// The object has been updated, and is now included in the query.
    case entered(T)

    /// The object has been updated, and is no longer included in the query.
    case left(T)

    /// The object has been created, and is a part of the query.
    case created(T)

    /// The object has been updated, and is still a part of the query.
    case updated(T)

    /// The object has been deleted, and is no longer included in the query.
    case deleted(T)

    init?(event: EventResponse<T>) {
        switch event.op {
        case .enter: self = .entered(event.object)
        case .leave: self = .left(event.object)
        case .create: self = .created(event.object)
        case .update: self = .updated(event.object)
        case .delete: self = .deleted(event.object)
        default: return nil
        }
    }

    public static func == <U>(lhs: Event<U>, rhs: Event<U>) -> Bool {
        switch (lhs, rhs) {
        case (.entered(let object1), .entered(let object2)): return object1 == object2
        case (.left(let object1), .left(let object2)):       return object1 == object2
        case (.created(let object1), .created(let object2)): return object1 == object2
        case (.updated(let object1), .updated(let object2)): return object1 == object2
        case (.deleted(let object1), .deleted(let object2)): return object1 == object2
        default: return false
        }
    }
}
