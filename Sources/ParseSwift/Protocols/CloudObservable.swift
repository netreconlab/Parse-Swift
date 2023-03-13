//
//  CloudObservable.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/11/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//
#if canImport(Combine)
import Foundation

/**
 This protocol describes the interface for creating a view model for `ParseCloud` functions and jobs.
 You can use this protocol on any custom class of yours, instead of `CloudViewModel`, if it fits your use case better.
 */
public protocol CloudObservable: ObservableObject {

    /// The `ParseObject` associated with this view model.
    associatedtype CloudCodeType: ParseCloudable

    /**
     Creates a new view model that can be used to handle updates.
     */
    init(cloudCode: CloudCodeType)

    /**
     Calls a Cloud Code function *asynchronously* and updates the view model
     when the result of its execution.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
    @MainActor
    func runFunction(options: API.Options) async

    /**
     Starts a Cloud Code Job *asynchronously* and updates the view model with the result and jobStatusId of the job.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
    */
    @MainActor
    func startJob(options: API.Options) async
}
#endif
