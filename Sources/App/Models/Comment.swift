//
//  Comment.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Foundation
import Fluent
import Vapor

final class Comment: Model, Content, @unchecked Sendable {
    static let schema = "comments"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "content")
    var content: String
    
    @Parent(key: "taskId")
    var task: Task
    
    @Parent(key: "userId")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, content: String, taskID: Task.IDValue, userID: User.IDValue) {
        self.id = id
        self.content = content
        self.$task.id = taskID
        self.$user.id = userID
    }
}
