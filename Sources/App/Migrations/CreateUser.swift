//
//  CreateUser.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Fluent

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }
        
        func prepare(on database: Database) async throws {
            try await database.schema("users")
                .id()
                .field("username", .string, .required)
                .field("passwordHash", .string, .required)
                .unique(on: "username")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
