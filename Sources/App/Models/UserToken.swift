//
//  UserToken.swift
//  todo-server
//
//  Created by Maxim Makarenkov on 09.12.2024.
//

import Fluent
import Vapor

final class UserToken: Model, Content, @unchecked Sendable {
    static let schema = "user_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "user_id")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = UUID.init(uuidString: value)
        self.value = value
        self.$user.id = userID
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user
    
    var isValid: Bool {
        true
    }
}
