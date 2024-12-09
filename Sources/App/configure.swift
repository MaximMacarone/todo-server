import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: "db",
        port: 5432,
        username: "vapor_username",
        password: "vapor_password",
        database: "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)
    
    app.middleware.use(AuthMiddleware())

    app.migrations.add(User.Migration())
    app.migrations.add(UserToken.Migration())
    app.migrations.add(CreateTask())
    app.migrations.add(CreateComment())
    
    try app.routes.register(collection: TaskController())
    try app.routes.register(collection: CommentController())

    // register routes
    try routes(app)
}
