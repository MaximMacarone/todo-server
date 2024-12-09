//
//  TaskController.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Vapor

struct TaskController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let tasks = routes.grouped("tasks")
        tasks.get(use: index)
        tasks.post(use: create)
        tasks.group(":taskID") { task in
            task.get(use: read)
            task.put(use: update)
            task.delete(use: delete)
        }
    }
    
    func index(_ req: Request) async throws -> [Task] {
        try await Task.query(on: req.db).all()
    }
    
    func create(_ req: Request) async throws -> Task {
        struct CreateTaskDTO: Content {
            var title: String
            var description: String
            var status: TaskStatus
        }
        
        let data = try req.content.decode(CreateTaskDTO.self)
        
        guard let user = req.auth.get(User.self) else {
            throw Abort(.unauthorized, reason: "User is not authenticated.")
        }
        
        let userId = user.id!
        
        let task = try Task(
            title: data.title,
            description: data.description,
            status: data.status,
            userID: user.requireID())
        try await task.save(on: req.db)
        return task
    }
    
    func read(_ req: Request) async throws -> Task {
        guard let task = try await Task.find(req.parameters.get("taskID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return task
    }
    
    func update(_ req: Request) async throws -> Task {
        struct UpdateTaskDTO: Content {
            var title: String
            var description: String
            var status: TaskStatus
        }
        guard let task = try await Task.find(req.parameters.get("taskID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedTask = try req.content.decode(UpdateTaskDTO.self)
        
        task.title = updatedTask.title
        task.description = updatedTask.description
        task.status = updatedTask.status
        try await task.save(on: req.db)
        return task
    }
    
    func delete(_ req: Request) async throws -> HTTPStatus {
        guard let task = try await Task.find(req.parameters.get("taskID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await task.delete(on: req.db)
        return .ok
    }
    
}
