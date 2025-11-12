////
////  SupabaseManager.swift
////  Dialysis One App
////
////  Created by user@22 on 10/11/25.
////
//
//import Foundation
//
//import Supabase
//
//class SupabaseManager {
//    
//    struct Profile: Encodable {
//        let id: String
//        let full_name: String
//        let email: String
//    }
//    
//    struct ProfileUpdate: Encodable {
//        let full_name: String
//        let updated_at: String
//    }
//    
//    static let shared = SupabaseManager()
//    
//    let client: SupabaseClient
//
//    private init() {
//        // Load credentials from Secrets.plist (not Info.plist)
//        guard
//            let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
//            let dict = NSDictionary(contentsOfFile: path),
//            let supabaseURLString = dict["SUPABASE_URL"] as? String,
//            let supabaseKeyString = dict["SUPABASE_KEY"] as? String,
//            let url = URL(string: supabaseURLString)
//        else {
//            fatalError("Missing or invalid Supabase credentials in Secrets.plist")
//        }
//
//        // Initialize Supabase client with loaded values
//        client = SupabaseClient(
//                supabaseURL: url,
//                supabaseKey: supabaseKeyString
//            )
//
//    }
//    
//    func signIn(email: String, password: String) async throws -> User {
//        let response = try await client.auth.signIn(email: email, password: password)
//        return response.user
//    }
//    
//    // MARK: - Sign Up
//    func signUp(email: String, password: String, fullName: String) async throws -> User {
//        // Sign up user and retrieve session
//        let response = try await client.auth.signUp(email: email, password: password)
//
//        guard let user = response.user else {
//            throw NSError(domain: "SupabaseManager", code: 0,
//                          userInfo: [NSLocalizedDescriptionKey: "User creation failed."])
//        }
//
//        guard let accessToken = response.session?.accessToken else {
//            throw NSError(domain: "SupabaseManager", code: 0,
//                          userInfo: [NSLocalizedDescriptionKey: "No access token returned from Supabase."])
//        }
//
//        // Create user profile payload
//        let profile = Profile(
//            id: user.id.uuidString,
//            full_name: fullName,
//            email: email
//        )
//
//        // ✅ Perform the insert with Authorization header manually
//        let insertResponse = try await client
//            .from("profiles")
//            .insert(profile)
//            .execute(options: FetchOptions(
//                headers: ["Authorization": "Bearer \(accessToken)"]
//            ))
//
//        print("✅ Profile inserted successfully: \(insertResponse)")
//
//        return user
//    }
//
//    // MARK: - Sign Out
//    func signOut() async throws {
//        try await client.auth.signOut()
//    }
//    
//    // MARK: - Get Current User
//    func getCurrentUser() async throws -> User? {
//        let session = try await client.auth.session
//        return session.user
//    }
//    
//    // MARK: - Reset Password (Send Email)
//    func sendPasswordResetEmail(email: String) async throws {
//        try await client.auth.resetPasswordForEmail(email)
//    }
//    
//    // MARK: - Update Password
//    func updatePassword(newPassword: String) async throws {
//        try await client.auth.update(user: UserAttributes(password: newPassword))
//    }
//    
//    // MARK: - Get User Profile
//    func getUserProfile(userId: String) async throws -> [String: Any]? {
//        let response = try await client
//            .from("profiles")
//            .select()
//            .eq("id", value: userId)
//            .single()
//            .execute()
//        
//        return try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
//    }
//    
//    // MARK: - Update User Profile
//    func updateUserProfile(userId: String, fullName: String) async throws {
//        let updates = ProfileUpdate(
//            full_name: fullName,
//            updated_at: ISO8601DateFormatter().string(from: Date())
//        )
//        
//        try await client
//            .from("profiles")
//            .update(updates)
//            .eq("id", value: userId)
//            .execute()
//    }
//}
