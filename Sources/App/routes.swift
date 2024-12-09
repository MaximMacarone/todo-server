import Fluent
import Vapor
      
func routes(_ app: Application) throws {

    
    app.post("users") {req async throws -> User in
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.passwordConfirmation else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        let user = try User(
            username: create.username,
            passwordHash: Bcrypt.hash(create.password)
            
        )
        try await user.save(on: req.db)
        return user
    }
    
    let passwordProtected = app.grouped(User.authenticator())
    passwordProtected.post("login") { req async throws -> UserToken in
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
    }
    
    let TokenProtected = app.grouped(UserToken.authenticator())
    TokenProtected.get("whoami") {req -> User in
        try req.auth.require(User.self)
    }

}
