//
//  CommentController.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Vapor

final class CommentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let authGroup = routes.grouped(AuthMiddleware())
        let comments = authGroup.grouped("comments")
        comments.get(use: index)
        comments.post(use: create)
        comments.group(":commentID") { comment in
            comment.get(use: read)
            comment.put(use: update)
            comment.delete(use: delete)
        }
    }
    
    func index(_ req: Request) async throws -> [Comment] {
        try await Comment.query(on: req.db).all()
    }
    
    func create(_ req: Request) async throws -> Comment {
        struct CreateCommentDTO: Content {
            var content: String
            var taskId: Task.IDValue
        }
        
        let data = try req.content.decode(CreateCommentDTO.self)
        
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User is not authenticated.")
        }
        
        let userId = user.id!
        
        guard let task = try await Task.find(data.taskId, on: req.db) else {
            throw Abort(.badRequest, reason: "Task with ID \(data.taskId) does not exist.")

        }
        
        let comment = try Comment(
            content: data.content,
            taskID: task.requireID(),
            userID: userId)
        try await comment.save(on: req.db)
        return comment
    }
    
    func read(_ req: Request) async throws -> Comment {
        guard let comment = try await Comment.find(req.parameters.get("commentID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return comment
    }
    
    func update(_ req: Request) async throws -> Comment {
        struct UpdateCommentDTO: Content {
            var updatedContent: String
        }
        guard let comment = try await Comment.find(req.parameters.get("commentID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedComment = try req.content.decode(UpdateCommentDTO.self)
        
        comment.content = updatedComment.updatedContent
        try await comment.save(on: req.db)
        return comment
    }
    
    func delete(_ req: Request) async throws -> HTTPStatus {
        guard let comment = try await Comment.find(req.parameters.get("commentID"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await comment.delete(on: req.db)
        return .ok
    }
}
