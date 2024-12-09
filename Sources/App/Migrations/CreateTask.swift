//
//  CreateTask.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Fluent

final class CreateTask: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("tasks")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("status", .string, .required)
            .field("createdAt", .datetime, .required)
            .field("userId", .uuid, .required, .references("users", "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("tasks").delete()
    }
}
