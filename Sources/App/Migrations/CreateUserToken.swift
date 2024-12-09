//
//  CreateUserToken.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }
        
        func prepare(on database: Database) async throws {
            try await database.schema("user_tokens")
                .id()
                .field("value", .string, .required)
                .field("user_id", .uuid, .required, .references("users", "id"))
                .unique(on: "value")
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema("user_tokens").delete()
        }
    }
}
