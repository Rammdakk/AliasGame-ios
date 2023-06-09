//  GameRoomScreenViewModel.swift
//  AliasGame
//
//  Created by Рамиль Зиганшин on 21.05.2023.
//

import SwiftUI
import Foundation


class GameRoomScreenViewModel: ObservableObject {
    // ViewModel for the game room screen
    
    @Published var errorState: ErrorState = .None
    @Published var navigationState: NavigationState
    @Published var teams: [TeamModel] = []
    @State var isAdmin = false
    
    // MARK: - Initialization
    
    init(navigationState: NavigationState, roomAdminID: String) {
        // Initialize the ViewModel with the provided navigation state
        isAdmin = (UserDefaults.standard.string(forKey: UserDefaultsKeys.USER_ID_KEY) == roomAdminID)
        self.errorState = .None
        self.navigationState = navigationState
        self.teams = []
        print(isAdmin)
        
    }
    
    // MARK: - Functions
    
    func leaveRoom(roomID: String) {
        // Method for leaving the game room
        
        guard var leaveRoomUrl = URL(string: UrlLinks.LEAVE_ROOM) else {
            // Check if the URL creation fails, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "URL creation error")
            return
        }

        guard let bearerToken = KeychainHelper.shared.read(service: userBearerTokenService, account: account, type: LoginResponse.self)?.value else {
            // Check if the bearer token is not available, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "Access denied")
            return
        }
        
        let queryItems = [URLQueryItem(name: "gameRoomId", value: roomID)]
        leaveRoomUrl.append(queryItems: queryItems)
        print(leaveRoomUrl)
        
        NetworkManager().makeNonReturningRequest(url: leaveRoomUrl, method: .get, parameters: nil, bearerToken: bearerToken) { result in
            switch result {
            case .success:
                // If the request is successful, update the navigationState to .Main and set the errorState to .Success with a message
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.USER_ROOM_KEY)
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.ROOM_INVIT_KEY)
                    self.leaveTeam()
                    self.navigationState = .Main
                    self.errorState = .Succes(message: "You left room")
                }
                return
            case .failure(let error):
                // Handle the error
                print(error)
                DispatchQueue.main.async {
                    self.errorState = .Error(message: "Error: \(error.errorMessage)")
                }
            }
        }
    }
    
    func leaveTeam() {
        // Method for leaving the game room
        
        guard var leaveTeamUrl = URL(string: UrlLinks.LEAVE_TEAM) else {
            // Check if the URL creation fails, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "URL creation error")
            return
        }

        guard let bearerToken = KeychainHelper.shared.read(service: userBearerTokenService, account: account, type: LoginResponse.self)?.value else {
            // Check if the bearer token is not available, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "Access denied")
            return
        }
        
        guard let teamID = UserDefaults.standard.string(forKey: UserDefaultsKeys.USER_TEAM_KEY) else {
            return
        }
        
        let queryItems = [URLQueryItem(name: "teamId", value: teamID)]
        leaveTeamUrl.append(queryItems: queryItems)
        print(leaveTeamUrl)
        
        NetworkManager().makeNonReturningRequest(url: leaveTeamUrl, method: .get, parameters: nil, bearerToken: bearerToken) { result in
            switch result {
            case .success:
                // If the request is successful, update the navigationState to .Main and set the errorState to .Success with a message
                DispatchQueue.main.async {
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.USER_TEAM_KEY)
                }
                return
            case .failure(let error):
                // Handle the error
                print(error)
                DispatchQueue.main.async {
                    self.errorState = .Error(message: "Error: \(error.errorMessage)")
                }
            }
        }
    }
    
    func loadTeams(roomID: String) {
        // Method for loading teams in the game room
        
        guard var loadTeamsURl = URL(string: UrlLinks.TEAMS_LIST) else {
            // Check if the URL creation fails, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "URL creation error")
            return
        }

        guard let bearerToken = KeychainHelper.shared.read(service: userBearerTokenService, account: account, type: LoginResponse.self)?.value else {
            // Check if the bearer token is not available, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "Access denied")
            return
        }
        
        let queryItems = [URLQueryItem(name: "gameRoomId", value: roomID)]
        loadTeamsURl.append(queryItems: queryItems)
        
        NetworkManager().makeRequest(url: loadTeamsURl, method: .get, parameters: nil, bearerToken: bearerToken) { (result: Result<[TeamModel]?, NetworkError>) in
            switch result {
            case .success(let data):
                // If the request is successful, update the teams array with the received data
                DispatchQueue.main.async {
                    self.teams = data ?? []
                }
                return
            case .failure(let error):
                // Handle the error
                print(error)
                DispatchQueue.main.async {
                    self.errorState = .Error(message: "Error: \(error.errorMessage)")
                }
            }
        }
    }
    
    func joinTeam(teamID: String, roomID: String) {
        // Method for joining a team in the game room
        
        guard let joinTeam = URL(string: UrlLinks.JOIN_TEAM) else {
            // Check if the URL creation fails, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "URL creation error")
            return
        }

        guard let bearerToken = KeychainHelper.shared.read(service: userBearerTokenService, account: account, type: LoginResponse.self)?.value else {
            // Check if the bearer token is not available, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "Access denied")
            return
        }
        
        let parameters = ["teamId": teamID] as [String : Any]
        print(joinTeam)
        
        NetworkManager().makeNonReturningRequest(url: joinTeam, method: .post, parameters: parameters, bearerToken: bearerToken) { result in
            switch result {
            case .success:
                UserDefaults.standard.set(teamID, forKey: UserDefaultsKeys.USER_TEAM_KEY)
                // If the request is successful, call loadTeams to update the teams array
                self.loadTeams(roomID: roomID)
                return
            case .failure(let error):
                // Handle the error
                print(error)
                DispatchQueue.main.async {
                    self.errorState = .Error(message: "Error: \(error.errorMessage)")
                }
            }
        }
    }
    
    func passAdmin(newAdminID: String, roomID: String) {
        // Method for passing the admin role to another user
        
        // This method wasn't ready (server crush) on the server, which was given.
        self.errorState = .Error(message: "Method has error on server. To avoid crush we stopped request. Please check passAdmin function in GameRoomScreenViewModel")
        return
        
        guard let passAdminURL = URL(string: UrlLinks.PASS_ADMIN) else {
            // Check if the URL creation fails, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "URL creation error")
            return
        }

        guard let bearerToken = KeychainHelper.shared.read(service: userBearerTokenService, account: account, type: LoginResponse.self)?.value else {
            // Check if the bearer token is not available, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "Access denied")
            return
        }
        
        let parameters = ["gameRoomId": roomID, "newAdminId": newAdminID] as [String : Any]
        NetworkManager().makeNonReturningRequest(url: passAdminURL, method: .post, parameters: parameters, bearerToken: bearerToken) { result in
            switch result {
            case .success:
                // If the request is successful, call loadTeams to update the teams array
                self.loadTeams(roomID: roomID)
                return
            case .failure(let error):
                // Handle the error
                print(error)
                DispatchQueue.main.async {
                    self.errorState = .Error(message: "Error: \(error.errorMessage)")
                }
            }
        }
    }
    
    func changeRoundStatus(roomID: String, url: String) {
        // Method for passing the admin role to another user
        
        guard let startRoundUrl = URL(string: url) else {
            // Check if the URL creation fails, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "URL creation error")
            return
        }

        guard let bearerToken = KeychainHelper.shared.read(service: userBearerTokenService, account: account, type: LoginResponse.self)?.value else {
            // Check if the bearer token is not available, set the errorState to .Error with a message and return
            self.errorState = .Error(message: "Access denied")
            return
        }
        
        let parameters = ["gameRoomId": roomID] as [String : Any]
        NetworkManager().makeRequest(url: startRoundUrl, method: .post, parameters: parameters, bearerToken: bearerToken) { (result: Result<RoundInfo?, NetworkError>) in
            switch result {
            case .success(let round):
                DispatchQueue.main.async {
                    self.errorState = .Succes(message: "Round state: \(round?.state ?? "undef")")
                }
                // If the request is successful, call loadTeams to update the teams array
                
                return
            case .failure(let error):
                // Handle the error
                print(error)
                DispatchQueue.main.async {
                    self.errorState = .Error(message: "Error: \(error.errorMessage)")
                }
            }
        }
    }
}


