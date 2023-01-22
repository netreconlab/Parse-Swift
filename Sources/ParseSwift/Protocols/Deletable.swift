//
//  Deletable.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/27/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

public protocol Deletable: Codable {
    associatedtype DeletingType

    func delete(options: API.Options) async throws -> DeletingType
    func delete() async throws -> DeletingType
}

extension Deletable {
    public func delete() async throws -> DeletingType {
        try await delete(options: [])
    }
}
