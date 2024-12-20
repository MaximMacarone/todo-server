//
//  TaskController.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Vapor
import Fluent

struct TaskController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let authGroup = routes.grouped(AuthMiddleware())
        let tasks = authGroup.grouped("tasks")
        tasks.get(use: index)
        tasks.get("export", use: exportTasks)
        tasks.get("sort", use: sortByDate)
        tasks.get("search", use: search)
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
    
    func read(_ req: Request) async throws -> TaskWithComments {
        guard let taskIDString = req.parameters.get("taskID"),
              let taskID = UUID(uuidString: taskIDString),
              let task = try await Task.query(on: req.db).filter(\.$id == taskID).first() else {
            throw Abort(.notFound)
        }
        
        let comments = try await Comment.query(on: req.db)
            .filter(\.$task.$id == task.id!)
            .all()
        
        let commentResponses = comments.map { CommentResponse(comment: $0) }
        
        let response = TaskWithComments(
            id: task.id,
            title: task.title,
            description: task.description,
            status: task.status.rawValue,
            createdAt: task.createdAt ?? Date(),
            comments: commentResponses
        )
        
        return response
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
    
    func exportTasks(_ req: Request) async throws -> Response {
        guard let format = req.query[String.self, at: "format"]?.lowercased() else {
            throw Abort(.badRequest, reason: "Please provide a valid format (json/csv) using query parameter 'format'")
        }
        
        let tasks = try await Task.query(on: req.db).with(\.$comments).all()
        
        switch format {
        case "json":
            return try await exportTasksAsJSON(tasks, req: req)
        case "csv":
            return try await exportTasksAsCSV(tasks, req: req)
        default:
            throw Abort(.badRequest, reason: "Invalid format. Use 'json' or 'csv'.")
        }
    }
    
    private func exportTasksAsJSON(_ tasks: [Task], req: Request) async throws -> Response {
        let response = Response(status: .ok)
        response.headers.add(name: "Content-Type", value: "application/json")
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        response.body = .init(data: try jsonEncoder.encode(tasks))
        
        return response
    }
    
    private func exportTasksAsCSV(_ tasks: [Task], req: Request) async throws -> Response {
        var csvString = "ID,Title,Description,Status,Created At,Comments Count\n"
        
        for task in tasks {
            let id = task.id?.uuidString ?? ""
            let title = task.title.replacingOccurrences(of: ",", with: " ")
            let description = task.description.replacingOccurrences(of: ",", with: " ")
            let status = task.status.rawValue
            let createdAt = task.createdAt?.description ?? ""
            let commentsCount = task.comments.count
            
            csvString += "\(id),\(title),\(description),\(status),\(createdAt),\(commentsCount)\n"
        }
        
        let response = Response(status: .ok)
        response.headers.add(name: "Content-Type", value: "text/csv")
        response.headers.add(name: "Content-Disposition", value: "attachment; filename=\"tasks.csv\"")
        response.body = .init(string: csvString)
        
        return response
    }
    
    func sortByDate(_ req: Request) async throws -> [Task] {
        // Читаем параметр сортировки из query
        let sortOrder = req.query[String.self, at: "order"] ?? "asc"

        let sortDirection: DatabaseQuery.Sort.Direction
        if sortOrder.lowercased() == "desc" {
            sortDirection = .descending
        } else {
            sortDirection = .ascending
        }

        let tasks = try await Task.query(on: req.db)
            .sort(\.$createdAt, sortDirection)
            .all()
        
        return tasks
    }
    
    func search(_ req: Request) async throws -> [Task] {
        guard let searchTerm = req.query[String.self, at: "title"] else {
            throw Abort(.badRequest, reason: "Missing 'title' query parameter")
        }

        let tasks = try await Task.query(on: req.db)
            .filter(\.$title ~~ searchTerm)
            .all()
        return tasks
    }
    
}
