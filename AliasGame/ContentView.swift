//
//  ContentView.swift
//  AliasGame
//
//  Created by Рамиль Зиганшин on 13.05.2023.
//

import SwiftUI

struct ContentView: View {
    @State private var navigationState: NavigationState = .Auth
    @State private var errorState: ErrorState = .None
    
    var body: some View {
        VStack {
            
            switch navigationState {
                
            case .Auth:
                AuthScreen(navigationState: $navigationState.animation(), errorState: $errorState.animation())
                
            case .Main:
                MainScreen(navigationState: $navigationState.animation(), errorState: $errorState.animation())
                
            case .RoomCreation:
                RoomCreationScreen(navigationState: $navigationState.animation(), errorState: $errorState.animation())
                
            case .Rooms:
                RoomsScreen(navigationState: $navigationState.animation(), errorState: $errorState.animation())
                
            case .GameRoom(let room):
                GameRoomScreen(navigationState: $navigationState.animation(), errorState: $errorState.animation(), room: room)
            }
        }.overlay (
            ErrorView(errorState: $errorState)
        )
    }
}

enum NavigationState {
    
    case Auth

    case Main
    
    case RoomCreation
    
    case Rooms
    
    case GameRoom(room: RoomModel)
}
