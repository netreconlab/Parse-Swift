//
//  ParseHookTriggerRequestable.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/24/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 Conforming to `ParseHookTriggerRequestable` allows you to create types that
 can decode requests when `ParseHookTriggerable` triggers are called.
 - requires: `.usePrimaryKey` has to be available. It is recommended to only
 use the primary key in server-side applications where the key is kept secure and not
 exposed to the public.
 */
public protocol ParseHookTriggerRequestable: ParseHookRequestable {
    /// The types of Parse Hook Trigger.
    var triggerName: String? { get }
    /// The number of clients connected.
    var clients: Int? { get }
}
