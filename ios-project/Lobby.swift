//
//  Lobby.swift
//  ios-project
//
//  Created by Spencer Joel on 2016-10-14.
//  Copyright © 2016 Manjot. All rights reserved.
//

import Foundation

class Lobby{
    
    enum LobbyJoinErrors: Error {
        case LobbyFull
        case LobbyCancelled
        case GameStarted
    }
    
    var settings : GameSetting
    var host : Profile
    var playerList:[LobbyUser]
    
    //will need a variable to hold the list of player tuples (player, ready, seeker)
    //will need a host/creater/user variable
    
    init(_ hostID : Profile) {
        settings = GameSetting()
        host = hostID
        playerList = [LobbyUser(hostID)]
        // settings.edit() - Allow the user to select the settings for the game
    }
    
    func editSettings(_ x: Int){ // TODO: take a Role later
        settings.edit()
    }
    
    //TODO: Implement these functions
    
    // Starts the game
    func lobbyStart(){}
    
    // Invites a player to the lobby
    func lobbyInvite(_ playerId: Profile){
        playerList.append(LobbyUser(playerId))
    }
    
    // Kicks a player from the lobby
    func lobbyKick(_ playerId: Profile){
        var index : Int = 0
        var count : Int = 0
        for temp in playerList{
            if(temp.profile === playerId){
                index = count
            }
            count += 1
        }
        playerList.remove(at: index)
    }
    
    // Allows the host to change a role of a player in the lobby
    func lobbyChangeRole(_ playerId: Profile){
        var index : Int = 0
        var count : Int = 0
        for temp in playerList{
            if(temp.profile === playerId){
                index = count
            }
            count += 1
        }
        playerList[index].isSeeker = !playerList[index].isSeeker
    }
    
    // Toggles the current users ready status
    func lobbyToggleReady(_ playerId: Profile){
        var index : Int = 0
        var count : Int = 0
        for temp in playerList{
            if(temp.profile === playerId){
                index = count
            }
            count += 1
        }
        playerList[index].isReady = !playerList[index].isReady

    }
    
    // Sets the ready status to false for all players in the lobby
    func lobbyResetReady(){
        for i in 0 ..< playerList.count{
            playerList[i].isReady = false
        }
    }
    
    // Closes the lobby
    func lobbyCloseLobby(){}
    
    //will need a function to add a player to the players list when that exists
    
    // Update the list when a new player joins the lobby
    func lobbyOnPlayerJoined(newPlayer: Profile) {
        playerList.append(LobbyUser(newPlayer));
        //players += [(profile: newPlayer, isReady: false, isSeeker: false)]
    }
    
    // Updates a players ready and seeker status when they change it
    func lobbyOnPlayerStateChanged(userName: String, ready: Bool, seeker: Bool) {
        for row in playerList {
            if (row.profile.userName == userName) {
                row.isReady = ready
                row.isSeeker = seeker
            }
        }
    }
    
    
    class func lobbyJoinLobby(_ profile: Profile, _ gameCode: String) throws -> Lobby?{
        
        if (gameCode.isEmpty) {
            return nil
        }
        
        let lobby = Lobby(profile) // server.find.lobby(gameCode)
        
        // check lobby status (players full, lobby canceled, game started)
        if (lobby.playerList.count == lobby.settings.maxPlayers) {
            throw LobbyJoinErrors.LobbyFull
        }
        // lobby.players += (profile, false, false))
        // server.notifyLobby(lobby)
    
        return lobby
    }
    
    
    class GameSetting{
        
        // MARK: - Fields
        private var _time: Int
        var time: Int {
            get{
                return _time
            }
            set(newValue) {
                do{
                    try setTime(newValue)
                } catch {
                    //do nothing
                }
            }
        }
        
        private func setTime(_ time : Int) throws {
            if (time > 0){
                _time = time
            }
            else
            {
                throw InvalidSettingError.invalidSetting
            }

        }
        
        private var _maxPlayers: Int
        var maxPlayers: Int {
            get{
                return _maxPlayers
            }
            set(newValue){
                if (newValue >= _minPlayers && newValue >= 2) {
                    _maxPlayers = newValue
                }
            }
        }
        
        private var _minPlayers: Int
        var minPlayers: Int {
            get{
                return _minPlayers
            }
            set(newValue){
                if (newValue <= _maxPlayers && newValue >= 2) {
                    _minPlayers = newValue
                }
            }
        }
        
        private var _gameCode: String
        var gameCode: String {
            get{
                return _gameCode
            }
        }
        
        // TODO: var Boundaries
        
        
        // MARK: - Methods
        init(){
            _time = 6000
            _maxPlayers = 1000
            _minPlayers = 2
            _gameCode = GameSetting.genCode()
        }
        
        //load view to change game settings
        func edit(){
            // test values for now... :
            time = 6001
            maxPlayers = 10
            minPlayers = 3
        }
        
        //change the bounds of the map when that exists
        func changeBounds(){
            // TODO: implement method
        }
        
        class func genCode() -> String{
            return "1"
        }
        
        enum InvalidSettingError: Error {
            case invalidSetting
        }
        
    }
    
    class LobbyUser{
        var profile : Profile
        var isReady : Bool
        var isSeeker : Bool
        
        init(_ playerId: Profile) {
            profile = playerId
            isReady = false
            isSeeker = false
        }
        
    }
}
