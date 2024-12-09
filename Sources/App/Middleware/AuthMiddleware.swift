//
//  AuthMiddleware.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Vapor

final class AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    
        guard let tokenString = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing or invalid token")
        }
        
        let userId = try await UserToken.find(tokenString, on: request.db)

        request.auth.login(user)

        return try await next.respond(to: request)
    }
}
