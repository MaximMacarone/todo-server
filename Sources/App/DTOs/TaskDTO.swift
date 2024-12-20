//
//  TaskDTO.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 10.12.2024.
//

import Foundation
import Vapor

struct TaskWithComments: Content {
    let id: UUID?
    let title: String
    let description: String
    let status: String
    let createdAt: Date
    let comments: [CommentResponse]
}

struct CommentResponse: Content {
    let id: UUID?
    let content: String
    let userID: UUID?
    
    init(comment: Comment) {
        self.id = comment.id
        self.content = comment.content
        self.userID = comment.$user.id
    }
}
