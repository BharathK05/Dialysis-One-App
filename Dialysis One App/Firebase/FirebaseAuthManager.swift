//
//  FirebaseAuthManager.swift
//  Dialysis One App
//
//  Created by user@22 on 11/11/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore

class FirebaseAuthManager {
    
    static let shared = FirebaseAuthManager()
    
    private init() {
        print("✅ FirebaseAuthManager initialized")
    }
    
    // MARK: - Sign Up
    /// Create a new user with email and password
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("❌ Sign up error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                let error = NSError(domain: "FirebaseAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "User creation failed"])
                completion(.failure(error))
                return
            }
            
            print("✅ User created successfully: \(user.uid)")
            
            // Send email verification
            user.sendEmailVerification { error in
                if let error = error {
                    print("⚠️ Email verification send failed: \(error.localizedDescription)")
                } else {
                    print("📧 Verification email sent to: \(email)")
                }
            }
            
            completion(.success(user))
        }
    }
    
    // MARK: - Sign In
    /// Sign in existing user with email and password
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("❌ Sign in error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                let error = NSError(domain: "FirebaseAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Sign in failed"])
                completion(.failure(error))
                return
            }
            
            print("✅ User signed in successfully: \(user.uid)")
            completion(.success(user))
        }
    }
    
    // MARK: - Sign Out
    /// Sign out current user
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            print("✅ User signed out successfully")
            completion(.success(()))
        } catch let error {
            print("❌ Sign out error: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    // MARK: - Get Current User
    /// Get currently authenticated user
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Check if User is Signed In
    /// Check if user is currently authenticated
    func isUserSignedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    // MARK: - Send Password Reset Email
    /// Send password reset email to user
    func sendPasswordResetEmail(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("❌ Password reset email error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Password reset email sent to: \(email)")
            completion(.success(()))
        }
    }
    
    // MARK: - Update Password
    /// Update current user's password
    func updatePassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "FirebaseAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
            completion(.failure(error))
            return
        }
        
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                print("❌ Password update error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Password updated successfully")
            completion(.success(()))
        }
    }
    
    // MARK: - Send Email Verification
    /// Send email verification to current user
    func sendEmailVerification(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "FirebaseAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
            completion(.failure(error))
            return
        }
        
        user.sendEmailVerification { error in
            if let error = error {
                print("❌ Email verification error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ Email verification sent")
            completion(.success(()))
        }
    }
    
    // MARK: - Reload User
    /// Reload current user data
    func reloadUser(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "FirebaseAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
            completion(.failure(error))
            return
        }
        
        user.reload { error in
            if let error = error {
                print("❌ Reload user error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ User data reloaded")
            completion(.success(()))
        }
    }
    
    // MARK: - Delete User Account
    /// Delete current user account
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            let error = NSError(domain: "FirebaseAuth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])
            completion(.failure(error))
            return
        }
        
        user.delete { error in
            if let error = error {
                print("❌ Delete account error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            print("✅ User account deleted")
            completion(.success(()))
        }
    }
    
    // MARK: - Get User Email
    /// Get current user's email
    func getUserEmail() -> String? {
        return Auth.auth().currentUser?.email
    }
    
    // MARK: - Get User ID
    /// Get current user's ID (UID)
    func getUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Check Email Verified
    /// Check if current user's email is verified
    func isEmailVerified() -> Bool {
        return Auth.auth().currentUser?.isEmailVerified ?? false
    }
}

// MARK: - Helper Extensions
extension FirebaseAuthManager {
    
    /// Validate email format
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Check password strength
    func isPasswordStrong(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    /// Get Firebase error message
    func getErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        
        print("🔥 Firebase Error Code: \(errorCode.rawValue) - \(errorCode)")
        
        switch errorCode {
        case .invalidEmail:
                return "The email address format is invalid."
                
            case .userNotFound:
                return "No account found with this email. Please sign up first."
                    
            case .wrongPassword:
                return "Incorrect password. Please try again."

            case .invalidCredential:
                return "Incorrect email or password. Please check and try again."
                
            case .userDisabled:
                return "This account has been disabled. Please contact support."
                
            case .tooManyRequests:
                return "Too many unsuccessful attempts. Please try again later."
                
            case .emailAlreadyInUse:
                return "This email is already registered. Please sign in instead."
                
            case .weakPassword:
                return "Your password is too weak. Please use at least 6 characters."
                
            case .networkError:
                return "Network error. Please check your internet connection."
                
            default:
                print("⚠️ Unhandled Firebase error: \(errorCode.rawValue) - \(nsError.localizedDescription)")
                return "Something went wrong. Please try again."
        }
        
        
        return error.localizedDescription
    }
}
