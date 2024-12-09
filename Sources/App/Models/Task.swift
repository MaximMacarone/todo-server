//
//  Task.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Foundation
import Fluent
import Vapor

enum TaskStatus: String, Codable {
    case completed = "completed"
    case inProgress = "inProgress"
}

final class Task: Model, Content, @unchecked Sendable {
    static let schema = "tasks"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Enum(key: "status")
    var status: TaskStatus
    
    @Parent(key: "userId")
    var user: User
    
    @Children(for: \.$task)
    var comments: [Comment]
    
    init() {}
    
    init(id: UUID? = nil, title: String, description: String, status: TaskStatus, userID: User.IDValue) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.$user.id = userID
    }
}
