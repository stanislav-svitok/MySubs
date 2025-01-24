//
//  GoogleAPI.swift
//  MySubs
//
//  Created by Stanislav Svitok on 22/01/2025.
//

import Foundation
import AuthenticationServices

class GoogleAPI {
    struct Token: Decodable {
        let accessToken: String
        let expiresIn: Int
        let tokenType: String
        let scope: String
        var refreshToken: String?
    }
    
    struct SubscriptionItem: Decodable {
        struct Thumbnail: Decodable {
            let url: String
            let width: Int?
            let height: Int?
        }
        
        struct Snippet: Decodable {
            struct Resource: Decodable {
                let kind: String
                let channelId: String
            }
            
            let publishedAt: String
            let channelTitle: String?
            let title: String
            let description: String
            let resourceId: Resource?
            let channelId: String?
            let thumbnails: [String: Thumbnail]
        }

        
        struct ContentDetail: Decodable {
            let totalItemCount: Int
            let newItemCount: Int
            let activityType: String
        }
        
        struct SubscriberSnippet: Decodable {
            let title: String
            let description: String
            let channelId: String
            let thumbnails:  [String: Thumbnail]
        }
        
        struct Statistics: Decodable {
            let viewCount: String
            let subscriberCount: String
            let hiddenSubscriberCount: Bool
            let videoCount: String
        }
        
        let kind: String
        let etag: String
        let id: String
        let snippet: Snippet
        let contentDetails: ContentDetail?
        let subscriberSnippet: SubscriberSnippet?
        
        let statistics: Statistics?
    }
    
    struct SubscriptionResponse: Decodable {
        struct PageInfo: Decodable {
            let totalResults: Int
            let resultsPerPage: Int
        }
        
        let kind: String
        let etag: String
        let nextPageToken: String?
        let prevPageToken: String?
        let pageInfo: PageInfo
        let items: [SubscriptionItem]
    }
    
    enum SignInError: Error {
        case missingCode
        case missingRefreshToken
    }
    
    enum ChannelError: Error {
        case notFound
    }
    
    static let shared = GoogleAPI()
    
    let callbackURLScheme = "com.svitok.stanislav.mysubs"
    let clientID = "569862668979-v23b12irkmf4b347rklfuliba4ultdk2.apps.googleusercontent.com"
    
    private var token: Token? = nil
    
    var isInitialised: Bool {
        Keychain.storedToken != nil
    }

    var accessURL: URL {
        URL(string: "https://accounts.google.com/o/oauth2/v2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube.readonly&response_type=code&redirect_uri=com.svitok.stanislav.mysubs%3A/oauth2redirect&client_id=\(clientID)")!
    }
    
    @discardableResult func exchangeCodeForToken(url: URL) async throws -> Token {
        guard let code = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw SignInError.missingCode
            
        }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: "com.svitok.stanislav.mysubs%3A/oauth2redirect"),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        let exchangeURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: exchangeURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = components.query?.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let token = try decoder.decode(Token.self, from: data)
        if let refreshToken = token.refreshToken {
            try? Keychain.storeLoginToken(refreshToken)
        }
        self.token = token
        return token
    }
    
    @discardableResult func refresh() async throws -> Token {
        guard let refreshToken = Keychain.storedToken else {
            throw SignInError.missingRefreshToken
        }
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
        ]
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        let exchangeURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: exchangeURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = components.query?.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        var token = try decoder.decode(Token.self, from: data)
        if let refreshToken = token.refreshToken {
            try? Keychain.storeLoginToken(refreshToken)
        } else {
            token.refreshToken = refreshToken
        }
        self.token = token
        return token
    }
    
    private init() {}
    
    func getSubscriptions(page: String? = nil) async throws -> SubscriptionResponse {
         
        guard let token else {
            try await refresh()
            return try await getSubscriptions()
        }
        
        let headers = [
            "Authorization": "Bearer \(token.accessToken)",
            "Accept": "application/json"
        ]
        
        var queries = [
            URLQueryItem(name: "mine", value: "true"),
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "order", value: "alphabetical"),
            URLQueryItem(name: "maxResults", value: "15"),
        ]
        if let page {
            queries.append(URLQueryItem(name: "pageToken", value: page))
        }
        let subscriptionsURL = URL(string: "https://www.googleapis.com/youtube/v3/subscriptions")!.appending(queryItems: queries)
        
        var request = URLRequest(url: subscriptionsURL)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(SubscriptionResponse.self, from: data)
        } catch {
            throw error
        }
    }
    
    func getAccount() async throws -> Account {
        guard let token else {
            try await refresh()
            return try await getAccount()
        }
        
        let headers = [
            "Authorization": "Bearer \(token.accessToken)",
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        let accountURL = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&mine=true")!
        
        var request = URLRequest(url: accountURL)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        do {
            let channels = try decoder.decode(SubscriptionResponse.self, from: data)
            let name = channels.items.first?.snippet.title ?? ""
            let picture = channels.items.first?.snippet.thumbnails["default"]?.url ?? ""
            return Account(picture: picture, name: name)
        } catch {
            throw error
        }
    }
    
    func get(channel: String) async throws -> SubscriptionItem {
        guard let token else {
            try await refresh()
            return try await get(channel: channel)
        }
        
        let headers = [
            "Authorization": "Bearer \(token.accessToken)",
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        let accountURL = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&id=\(channel)")!
        
        var request = URLRequest(url: accountURL)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        do {
            let channels = try decoder.decode(SubscriptionResponse.self, from: data)
            guard let channel = channels.items.first else {
                throw ChannelError.notFound
            }
            
            return channel
        } catch {
            throw error
        }
    }
    
    func logout() {
        try? Keychain.clearLoginToken()
        token = nil
    }
}
