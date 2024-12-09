//
//  AuthMiddleware.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Vapor
import Fluent

final class AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    
        guard let tokenString = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing or invalid token")
        }
        
        guard let token = try await UserToken.query(on: request.db)
            .filter(\.$value == tokenString)
            .with(\.$user)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid token.")
        }

        request.auth.login(token.user)

        return try await next.respond(to: request)
    }
}
