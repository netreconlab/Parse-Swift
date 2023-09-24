//
//  Savable.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

public protocol Savable: Encodable {
    associatedtype SavingType

    func save(options: API.Options) async throws -> SavingType
    func save() async throws -> SavingType
    func isSaved() async throws -> Bool
}

extension Savable {
    public func save() async throws -> SavingType {
        try await save(options: [])
    }
}
