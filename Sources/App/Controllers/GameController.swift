//
//  GameController.swift
//  SocketTestPackageDescription
//
//  Created by Steliyan H. on 29.03.18.
//

import Vapor
import HTTP

class GameController {
  
  var players: [String: WebSocket]
  var droplet: Droplet
  
  init(drop: Droplet) {
    players = [:]
    droplet = drop
    
    droplet.socket("ws", handler: socketHandler)
  }
  
  func socketHandler(request: Request, socket: WebSocket) throws {
    var scribPlayer: String? = nil
    
    try background {
      while socket.state == .open {
        try? socket.ping()
        self.droplet.console.wait(seconds: 5)
      }
    }
    
    socket.onText = { socket, message in
      let json = try JSON(bytes: Array(message.utf8))
      
      guard let msgType = json.object?["command"]?.string, let player = json.object?["player"]?.string else {
        return
      }
      
      if msgType.equals(caseInsensitive: "connect") {
        scribPlayer = player
        self.players[player] = socket
        
        let response = try JSON(node: [
          "command":"connected",
          "username": player
          ])
        
        for (_, connection) in self.players {
          try connection.send(response)
        }
      } else if (msgType.equals(caseInsensitive: "clear")) {
        for (_, connection) in self.players {
          try connection.send(json)
        }
      } else {
        
        for (scrib, connection) in self.players {
          if (!scrib.equals(caseInsensitive: player)) {
            try connection.send(json)
          }
        }
      }
    }
    
    socket.onClose = { ws, _, _, _ in
      guard let player = scribPlayer else {
        return
      }
      
      let disconn = try JSON(node: [
        "command": "disconnect",
        "username": player
        ])
      
      for (remote, connection) in self.players {
        if (!remote.equals(caseInsensitive: player)) {
          try connection.send(disconn)
        }
      }
      
      self.players.removeValue(forKey: player)
    }
  }
}

extension WebSocket {
  func send(_ json: JSON) throws {
    let data = try json.makeBytes()
    
    try send(data.makeString())
  }
}


