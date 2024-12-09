//
//  CommentController.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Vapor

final class CommentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let comments = routes.grouped("comments")
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
        let comment = try req.content.decode(Comment.self)
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
        guard let comment = try await Comment.find(req.parameters.get("commentID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedComment = try req.content.decode(Comment.self)
        comment.content = updatedComment.content
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
