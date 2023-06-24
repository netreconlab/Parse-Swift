//
//  ParseHookTrigger.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/23/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 A generic Parse Hook Trigger type that can be used to create any Hook Trigger.
 */
public struct ParseHookTrigger: ParseHookTriggerable {
    public var className: String?
    public var triggerName: ParseHookTriggerType?
    public var url: URL?

    public init() {}
}
