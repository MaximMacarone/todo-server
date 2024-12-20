//
//  CreateComment.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Fluent

struct CreateComment: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("comments")
            .id()
            .field("content", .string, .required)
            .field("taskId", .uuid, .required, .references("tasks", "id"))
            .field("userId", .uuid, .required, .references("users", "id"))
            .foreignKey("taskId", references: "tasks", .id, onDelete: .cascade)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("comments").delete()
    }
}
